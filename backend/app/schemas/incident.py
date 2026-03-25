from pydantic import BaseModel


class ResponseRecordRead(BaseModel):
    name: str
    status: str
    detail: str
    rank: int

    model_config = {"from_attributes": True}


class IncidentRead(BaseModel):
    title: str
    team: str
    location: str
    created: str
    notes: str
    active: bool
    responses: list[ResponseRecordRead]
