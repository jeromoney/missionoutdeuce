from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.time import utc_now
from app.db.base import Base


class DeliveryEvent(Base):
    __tablename__ = "delivery_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255))
    detail: Mapped[str] = mapped_column(Text)
    time_label: Mapped[str] = mapped_column(String(50))
    icon: Mapped[str] = mapped_column(String(50), default="notifications")
    color: Mapped[str] = mapped_column(String(20), default="#4F6F95")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
