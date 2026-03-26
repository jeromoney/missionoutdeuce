from pydantic import BaseModel


class HealthRead(BaseModel):
    status: str
    database: str


class RootRead(BaseModel):
    name: str
    status: str
    health: str
    docs: str
