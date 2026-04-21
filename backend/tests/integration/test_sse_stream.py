import asyncio

import pytest

from app.realtime import event_broker


async def test_event_broker_delivers_to_team_subscriber():
    subscription_id, queue = event_broker.subscribe(team_ids={42})
    try:
        event_broker.publish(
            event_type="incident.created",
            team_id=42,
            payload={"incident_public_id": "pid-match"},
        )
        message = await asyncio.wait_for(queue.get(), timeout=2)
        assert "event: incident.created" in message
        assert "pid-match" in message
    finally:
        event_broker.unsubscribe(subscription_id)


async def test_event_broker_filters_out_non_matching_team():
    subscription_id, queue = event_broker.subscribe(team_ids={1})
    try:
        event_broker.publish(
            event_type="incident.created",
            team_id=999,
            payload={"incident_public_id": "pid-blocked"},
        )
        with pytest.raises(asyncio.TimeoutError):
            await asyncio.wait_for(queue.get(), timeout=0.3)
    finally:
        event_broker.unsubscribe(subscription_id)


async def test_event_broker_delivers_to_multiple_subscribers_of_same_team():
    sub_a, queue_a = event_broker.subscribe(team_ids={7})
    sub_b, queue_b = event_broker.subscribe(team_ids={7})
    try:
        event_broker.publish(
            event_type="incident.created",
            team_id=7,
            payload={"incident_public_id": "pid-fanout"},
        )
        message_a = await asyncio.wait_for(queue_a.get(), timeout=2)
        message_b = await asyncio.wait_for(queue_b.get(), timeout=2)
        assert "pid-fanout" in message_a
        assert "pid-fanout" in message_b
    finally:
        event_broker.unsubscribe(sub_a)
        event_broker.unsubscribe(sub_b)


