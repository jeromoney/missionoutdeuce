from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255))
    legacy_team_name: Mapped[str] = mapped_column("team", String(255))
    team_id: Mapped[int | None] = mapped_column(
        ForeignKey("teams.id", ondelete="RESTRICT"),
        nullable=True,
        index=True,
    )
    location: Mapped[str] = mapped_column(String(255))
    notes: Mapped[str] = mapped_column(Text)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    team_ref: Mapped["Team | None"] = relationship()
    responses: Mapped[list["ResponseRecord"]] = relationship(
        back_populates="incident",
        cascade="all, delete-orphan",
        order_by="ResponseRecord.rank",
    )


class ResponseRecord(Base):
    __tablename__ = "responses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    incident_id: Mapped[int] = mapped_column(ForeignKey("incidents.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(50))
    detail: Mapped[str] = mapped_column(Text)
    rank: Mapped[int] = mapped_column(Integer, default=1)

    incident: Mapped[Incident] = relationship(back_populates="responses")
