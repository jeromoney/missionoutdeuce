from pydantic import BaseModel


# Keep these request and response shapes aligned with contracts/openapi.json.
class DeliveryEventRead(BaseModel):
    title: str
    detail: str
    time: str
    icon: str
    color: str
