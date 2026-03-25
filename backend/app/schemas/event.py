from pydantic import BaseModel


# Keep these request and response shapes aligned with docs/api-contracts.md.
class DeliveryEventRead(BaseModel):
    title: str
    detail: str
    time: str
    icon: str
    color: str