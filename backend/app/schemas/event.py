from pydantic import BaseModel


class DeliveryEventRead(BaseModel):
    title: str
    detail: str
    time: str
    icon: str
    color: str
