from datetime import datetime, timezone


def relative_time_label(value: datetime) -> str:
    now = datetime.now(timezone.utc)
    target = value.replace(tzinfo=timezone.utc)
    delta = now - target
    minutes = max(int(delta.total_seconds() // 60), 0)

    if minutes < 1:
        return "just now"
    if minutes < 60:
        return f"{minutes} min ago"

    hours = minutes // 60
    if hours < 24:
        return f"{hours} hr ago"

    days = hours // 24
    return f"{days} d ago"
