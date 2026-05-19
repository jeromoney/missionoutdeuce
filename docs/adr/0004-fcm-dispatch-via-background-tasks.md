# FCM Dispatch via FastAPI BackgroundTasks

FCM messages are sent from a FastAPI `BackgroundTask` that runs after the HTTP response is returned, not synchronously in the request nor from a separate worker process.

## Considered Options

**Synchronous inline dispatch** — call Firebase Admin SDK inside `create_incident` / `update_incident` before returning the HTTP response. Simple, but FCM latency or outages block the dispatcher's request and risk transaction rollback on network error.

**Separate worker process** — a polling loop reads `PushDelivery` rows with `state="created"` and sends them, supporting durable retries. Most resilient. The `state`, `attempt_count`, and `last_error` columns on `PushDelivery` were designed with this in mind. Adds infrastructure (a second process, a polling interval) to what is currently a single-process Render deployment.

**FastAPI BackgroundTasks (chosen)** — after `db.commit()` the incident write, FCM sends are enqueued as a `BackgroundTask`. The HTTP response is returned immediately; FCM runs in the same process after the response is flushed. `PushDelivery` rows are updated with `state="sent"` or `state="failed"` and `last_error` by the task.

## Consequences

- Dispatcher response latency is not affected by FCM round-trip time or transient FCM errors.
- If the process crashes in the window between HTTP response and FCM send, those `PushDelivery` rows remain in `state="created"` indefinitely. There is no automatic retry. This is an accepted gap for the current deployment scale.
- `PushDelivery.state`, `attempt_count`, and `last_error` provide an audit trail for observability. The planned team-level monitoring system can detect stale `state="created"` rows as a signal of dispatch failure.
- A permanent FCM error (`NOT_REGISTERED`) in the BackgroundTask sets `Device.is_active = False` for that token. All other errors are logged to `PushDelivery.last_error` but leave the Device active.
- Migrating to a worker process later is straightforward: replace the BackgroundTask enqueue call with a queue push. The `PushDelivery` schema already supports it.
