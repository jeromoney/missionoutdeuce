from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.ids import generate_public_id
from app.core.time import utc_now
from app.db.base import Base


class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    public_id: Mapped[str] = mapped_column(String(36), unique=True, index=True, default=generate_public_id)
    title: Mapped[str] = mapped_column(String(255))
    team_id: Mapped[int | None] = mapped_column(
        ForeignKey("teams.id", ondelete="RESTRICT"),
        nullable=True,
        index=True,
    )
    location: Mapped[str] = mapped_column(String(255))
    notes: Mapped[str] = mapped_column(Text)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    # Monotonic per-incident version. Incremented on every PATCH; paired with
    # the matching incident_events row via UNIQUE (incident_id, version).
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)

    team_ref: Mapped["Team | None"] = relationship()
    responses: Mapped[list["ResponseRecord"]] = relationship(
        back_populates="incident",
        cascade="all, delete-orphan",
        order_by="ResponseRecord.rank",
    )


class ResponseRecord(Base):
    __tablename__ = "responses"
    __table_args__ = (
        UniqueConstraint("incident_id", "user_id", name="uq_responses_incident_user"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    incident_id: Mapped[int] = mapped_column(ForeignKey("incidents.id", ondelete="CASCADE"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(50))
    source: Mapped[str] = mapped_column(String(50))
    rank: Mapped[int] = mapped_column(Integer, default=1)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now)

    incident: Mapped[Incident] = relationship(back_populates="responses")
    user: Mapped["User"] = relationship()
