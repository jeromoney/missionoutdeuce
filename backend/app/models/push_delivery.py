from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.time import utc_now
from app.db.base import Base


# Portable across SQLite + Postgres: avoids ::int cast that PG accepts but
# SQLite rejects. Enforces exactly one of the two target FKs is non-null.
_SINGLE_TARGET_CHECK = (
    "(CASE WHEN device_id IS NOT NULL THEN 1 ELSE 0 END) + "
    "(CASE WHEN web_push_subscription_id IS NOT NULL THEN 1 ELSE 0 END) = 1"
)


class PushDelivery(Base):
    __tablename__ = "push_deliveries"
    __table_args__ = (
        CheckConstraint(_SINGLE_TARGET_CHECK, name="ck_push_deliveries_single_target"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    incident_id: Mapped[int] = mapped_column(
        ForeignKey("incidents.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    device_id: Mapped[int | None] = mapped_column(
        ForeignKey("devices.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    web_push_subscription_id: Mapped[int | None] = mapped_column(
        ForeignKey("web_push_subscriptions.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    channel: Mapped[str] = mapped_column(String(16), nullable=False)
    event_type: Mapped[str] = mapped_column(String(64), nullable=False)
    state: Mapped[str] = mapped_column(String(16), default="created", nullable=False)
    attempt_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_attempt_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, onupdate=utc_now
    )

    incident: Mapped["Incident"] = relationship()  # type: ignore[name-defined]  # noqa: F821
    device: Mapped["Device | None"] = relationship()  # type: ignore[name-defined]  # noqa: F821
    web_push_subscription: Mapped["WebPushSubscription | None"] = relationship()  # type: ignore[name-defined]  # noqa: F821
