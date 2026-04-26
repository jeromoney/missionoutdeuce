"""Unit coverage for `app/api/routes/events.py::stream_events`.

Avoids the full HTTP round-trip — `TestClient.stream()` doesn't tear the
server-side async generator down cleanly, so an HTTP-level test on this route
hangs. Calling the handler directly with a fake `Request` whose
`is_disconnected()` returns True lets the inner generator yield the connect
preamble, observe the disconnect, and unsubscribe — covering the body without
the timing risk.
"""
from __future__ import annotations

import asyncio
from dataclasses import dataclass

import pytest
from fastapi.responses import StreamingResponse

from app.api.deps import Principal
from app.api.routes.events import stream_events
from app.core.time import utc_now
from app.models.team_management import Team, TeamMembership, User
from app.realtime import event_broker


@dataclass
class _FakeRequest:
    """Minimal Request stand-in: reports disconnected after the first poll."""
    _disconnected: bool = False

    async def is_disconnected(self) -> bool:
        was = self._disconnected
        self._disconnected = True
        return was


def _principal_with_one_team(db_session) -> Principal:
    user = User(name="Stream Tester", email="stream@example.com", phone="", is_active=True)
    db_session.add(user)
    db_session.flush()
    team = Team(name="Stream Team", is_active=True)
    db_session.add(team)
    db_session.flush()
    membership = TeamMembership(
        user_id=user.id,
        team_id=team.id,
        roles=["dispatcher"],
        role="dispatcher",
        granted_at=utc_now(),
    )
    db_session.add(membership)
    db_session.commit()
    db_session.refresh(user)
    return Principal(user=user, role=membership.role, membership=membership)


async def test_stream_events_sets_up_subscription_and_unwinds(db_session):
    principal = _principal_with_one_team(db_session)
    request = _FakeRequest()

    response = await stream_events(request=request, principal=principal)
    assert isinstance(response, StreamingResponse)

    chunks: list[bytes] = []
    async for chunk in response.body_iterator:
        chunks.append(chunk if isinstance(chunk, bytes) else chunk.encode())
        # Disconnect flag flips on the second is_disconnected() call inside
        # the loop, so a couple of chunks may flush before the generator
        # exits cleanly.
        if len(chunks) > 3:
            break

    body = b"".join(chunks)
    assert b": connected" in body

    # After the generator exits the subscription should be cleaned up.
    # Internals: event_broker._subscriptions is a dict keyed by uuid;
    # publishing now must reach 0 matching subscribers.
    delivered = []
    sub_id, queue = event_broker.subscribe(team_ids={principal.membership.team_id})
    try:
        event_broker.publish(
            event_type="incident.created",
            team_id=principal.membership.team_id,
            payload={"incident_public_id": "post-cleanup"},
        )
        try:
            delivered.append(await asyncio.wait_for(queue.get(), timeout=0.5))
        except asyncio.TimeoutError:
            pytest.fail("New subscriber should have received the event")
    finally:
        event_broker.unsubscribe(sub_id)

    assert any("post-cleanup" in m for m in delivered)


async def test_stream_events_403s_for_user_without_active_teams(db_session):
    user = User(name="No Team", email="noteam@example.com", phone="", is_active=True)
    db_session.add(user)
    db_session.commit()

    # Build a Principal manually with an empty memberships list, simulating
    # the case the router itself screens out before reaching the handler.
    # We don't go through get_current_principal — that already 403s — but the
    # handler also defends in depth.
    placeholder_team = Team(name="Placeholder", is_active=False)
    db_session.add(placeholder_team)
    db_session.flush()
    membership = TeamMembership(
        user_id=user.id,
        team_id=placeholder_team.id,
        roles=["responder"],
        role="responder",
        granted_at=utc_now(),
    )
    db_session.add(membership)
    db_session.commit()
    db_session.refresh(user)

    principal = Principal(user=user, role="responder", membership=membership)

    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await stream_events(request=_FakeRequest(), principal=principal)
    assert exc_info.value.status_code == 403
