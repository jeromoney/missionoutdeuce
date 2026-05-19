import json
from contextlib import asynccontextmanager

import firebase_admin
from firebase_admin import credentials
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import devices, events, health, incidents, team_management, users
from app.core.config import settings
from app.db.base import Base
from app.db.bootstrap import (
    ensure_device_client_and_availability,
    ensure_email_code_failed_attempts,
    ensure_incident_team_fk,
    ensure_incident_version,
    ensure_public_ids,
    ensure_response_record_fields,
    ensure_team_membership_is_active,
    ensure_team_membership_role,
)
from app.db.rls import apply_rls_policies
from app.db.session import engine
from app.models import (
    DeliveryEvent,
    Device,
    EmailCodeToken,
    Incident,
    IncidentEvent,
    PushDelivery,
    ResponseRecord,
    RefreshToken,
    Team,
    TeamMembership,
    User,
    WebPushSubscription,
)
from app.schemas.meta import RootRead


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.firebase_service_account_json and not firebase_admin._apps:
        cred = credentials.Certificate(json.loads(settings.firebase_service_account_json))
        firebase_admin.initialize_app(cred)

    Base.metadata.create_all(bind=engine)
    ensure_incident_team_fk(engine)
    ensure_public_ids(engine)
    ensure_response_record_fields(engine)
    ensure_incident_version(engine)
    ensure_team_membership_role(engine)
    ensure_team_membership_is_active(engine)
    ensure_email_code_failed_attempts(engine)
    ensure_device_client_and_availability(engine)
    apply_rls_policies(engine)
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description=(
        "MissionOut API contract for dispatcher, team admin, and responder "
        "clients. The exported OpenAPI document in contracts/openapi.json is "
        "the cross-stack source of truth."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_origin_regex=settings.allowed_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(health.router)
app.include_router(incidents.router)
app.include_router(events.router)
app.include_router(devices.router)
app.include_router(team_management.router)


@app.get("/", tags=["meta"], response_model=RootRead)
def root():
    return {
        "name": settings.app_name,
        "status": "ok",
        "health": "/health",
        "docs": "/docs",
    }
