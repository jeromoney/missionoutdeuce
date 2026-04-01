import asyncio
import json
import threading
import uuid
from dataclasses import dataclass


@dataclass
class _Subscription:
    team_ids: frozenset[int]
    queue: asyncio.Queue[str]
    loop: asyncio.AbstractEventLoop


class EventBroker:
    def __init__(self) -> None:
        self._subscriptions: dict[str, _Subscription] = {}
        self._lock = threading.Lock()

    def subscribe(self, *, team_ids: set[int]) -> tuple[str, asyncio.Queue[str]]:
        subscription_id = str(uuid.uuid4())
        queue: asyncio.Queue[str] = asyncio.Queue()
        subscription = _Subscription(
            team_ids=frozenset(team_ids),
            queue=queue,
            loop=asyncio.get_running_loop(),
        )
        with self._lock:
            self._subscriptions[subscription_id] = subscription
        return subscription_id, queue

    def unsubscribe(self, subscription_id: str) -> None:
        with self._lock:
            self._subscriptions.pop(subscription_id, None)

    def publish(self, *, event_type: str, team_id: int, payload: dict) -> None:
        message = self._format_sse(event_type=event_type, payload=payload)
        with self._lock:
            matching_subscriptions = [
                subscription
                for subscription in self._subscriptions.values()
                if team_id in subscription.team_ids
            ]

        for subscription in matching_subscriptions:
            subscription.loop.call_soon_threadsafe(
                subscription.queue.put_nowait,
                message,
            )

    @staticmethod
    def _format_sse(*, event_type: str, payload: dict) -> str:
        return f"event: {event_type}\ndata: {json.dumps(payload)}\n\n"


event_broker = EventBroker()
