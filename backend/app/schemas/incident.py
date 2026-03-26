from pydantic import BaseModel


# Keep these request and response shapes aligned with contracts/openapi.json.
class ResponseRecordRead(BaseModel):
    name: str
    status: str
    detail: str
    rank: int

    model_config = {"from_attributes": True}


class IncidentRead(BaseModel):
    id: int
    title: str
    team: str
    location: str
    created: str
    notes: str
    active: bool
    responses: list[ResponseRecordRead]


class IncidentCreate(BaseModel):
    title: str
    team: str
    location: str
    notes: str
    active: bool = True


class IncidentUpdate(BaseModel):
    title: str
    location: str
    notes: str
    active: bool
