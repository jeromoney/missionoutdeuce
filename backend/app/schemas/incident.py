from datetime import datetime
from typing import Literal

from pydantic import BaseModel


PageGroup = Literal["responder", "dispatchers"]


# Keep these request and response shapes aligned with contracts/openapi.json.
class ResponseRecordCreate(BaseModel):
    status: str
    source: str
    rank: int = 1


class ResponseRecordRead(BaseModel):
    user_public_id: str
    status: str
    rank: int
    updated: datetime


class IncidentRead(BaseModel):
    public_id: str
    title: str
    team_public_id: str | None = None
    location: str
    created: datetime
    notes: str
    active: bool
    responses: list[ResponseRecordRead]


class IncidentCreate(BaseModel):
    title: str
    team_public_id: str
    location: str
    notes: str
    active: bool = True


class IncidentUpdate(BaseModel):
    title: str
    location: str
    notes: str
    active: bool
    # Page-group selector for the optional incident.paged event that follows
    # incident.updated. Defaults to "responder" (page everyone) per
    # docs/page-logic.md. `null` skips paging entirely.
    page_group: PageGroup | None = "responder"
