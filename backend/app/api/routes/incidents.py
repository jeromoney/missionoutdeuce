from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import Principal, get_current_principal
from app.core.time import utc_now
from app.db.session import get_db
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import TeamMembership
from app.realtime import event_broker
from app.schemas.incident import (
    IncidentCreate,
    IncidentRead,
    IncidentUpdate,
    ResponseRecordCreate,
    ResponseRecordRead,
)
from app.services import incidents as incident_service


router = APIRouter(prefix="/incidents", tags=["incidents"])

_DISPATCH_ROLES = {"team_admin", "dispatcher"}


def _serialize_incident(incident: Incident) -> IncidentRead:
    return IncidentRead(
        public_id=incident.public_id,
        title=incident.title,
        team_public_id=incident.team_ref.public_id if incident.team_ref is not None else None,
        location=incident.location,
        created=incident.created_at,
        notes=incident.notes,
        active=incident.active,
        responses=[
            ResponseRecordRead(
                user_public_id=response.user.public_id,
                status=response.status,
                rank=response.rank,
                updated=response.updated_at,
            )
            for response in incident.responses
        ],
    )


def _dispatch_memberships(principal: Principal) -> list[TeamMembership]:
    return [
        membership
        for membership in principal.user.memberships
        if membership.team.is_active
        and (
            membership.role in _DISPATCH_ROLES
            or _DISPATCH_ROLES.intersection(membership.roles or [])
        )
    ]


@router.get("", response_model=list[IncidentRead])
def list_incidents(
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    visible_team_ids = sorted(
        {
            membership.team_id
            for membership in principal.user.memberships
            if membership.team.is_active
        }
    )
    if not visible_team_ids:
        return []

    recent_cutoff = utc_now() - timedelta(days=7)
    statement = (
        select(Incident)
        .options(
            selectinload(Incident.responses).selectinload(ResponseRecord.user),
            selectinload(Incident.team_ref),
        )
        .where(Incident.created_at >= recent_cutoff)
        .where(Incident.team_id.in_(visible_team_ids))
        .order_by(Incident.created_at.desc())
    )

    incidents = db.scalars(statement).all()

    return [_serialize_incident(incident) for incident in incidents]


@router.post("", response_model=IncidentRead, status_code=201)
def create_incident(
    payload: IncidentCreate,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    dispatch_memberships = _dispatch_memberships(principal)
    if not dispatch_memberships:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user does not have dispatcher access for any team.",
        )

    matching_membership = next(
        (
            membership
            for membership in dispatch_memberships
            if membership.team.public_id == payload.team_public_id
        ),
        None,
    )
    if matching_membership is not None:
        team = matching_membership.team
    elif len(dispatch_memberships) == 1:
        team = dispatch_memberships[0].team
    else:
        raise HTTPException(
            status_code=400,
            detail="Requested team is not available to the authenticated dispatcher.",
        )

    incident = incident_service.create_incident(db=db, payload=payload, team=team)
    db.refresh(team)

    event_broker.publish(
        event_type="incident.created",
        team_id=team.id,
        payload={
            "incident_public_id": incident.public_id,
            "team_public_id": team.public_id,
            "title": incident.title,
            "created": incident.created_at.isoformat(),
        },
    )
    return _serialize_incident(incident)


@router.patch("/{incident_public_id}", response_model=IncidentRead)
def update_incident(
    incident_public_id: str,
    payload: IncidentUpdate,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    incident = db.scalar(
        select(Incident)
        .options(
            selectinload(Incident.responses).selectinload(ResponseRecord.user),
            selectinload(Incident.team_ref),
        )
        .where(Incident.public_id == incident_public_id)
    )
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")

    authorized = any(
        membership.team_id == incident.team_id
        and membership.team.is_active
        and (
            membership.role in _DISPATCH_ROLES
            or _DISPATCH_ROLES.intersection(membership.roles or [])
        )
        for membership in principal.user.memberships
    )
    if not authorized:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user does not have dispatcher access for this incident.",
        )

    incident = incident_service.update_incident(db=db, incident=incident, payload=payload)
    return _serialize_incident(incident)


@router.post("/{incident_public_id}/responses", response_model=ResponseRecordRead, status_code=201)
def create_incident_response(
    incident_public_id: str,
    payload: ResponseRecordCreate,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    incident = db.scalar(
        select(Incident)
        .options(selectinload(Incident.team_ref))
        .where(Incident.public_id == incident_public_id)
    )
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")

    authorized_membership = next(
        (
            membership
            for membership in principal.user.memberships
            if membership.team_id == incident.team_id
        ),
        None,
    )
    if authorized_membership is None:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user does not belong to the incident team.",
        )

    response = db.scalar(
        select(ResponseRecord)
        .options(selectinload(ResponseRecord.user))
        .where(
            ResponseRecord.incident_id == incident.id,
            ResponseRecord.user_id == principal.user.id,
        )
    )

    if response is None:
        response = ResponseRecord(
            incident_id=incident.id,
            user_id=principal.user.id,
            status=payload.status,
            source=payload.source,
            rank=payload.rank,
        )
        db.add(response)
    else:
        response.status = payload.status
        response.source = payload.source
        response.rank = payload.rank

    db.commit()
    db.refresh(response)
    db.refresh(principal.user)
    return ResponseRecordRead(
        user_public_id=principal.user.public_id,
        status=response.status,
        rank=response.rank,
        updated=response.updated_at,
    )
