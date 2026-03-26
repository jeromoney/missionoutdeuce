from pydantic import BaseModel


# Keep these request and response shapes aligned with contracts/openapi.json.
class GoogleAuthRequest(BaseModel):
    id_token: str
    requested_role: str


class AuthUserRead(BaseModel):
    name: str
    initials: str
    role: str
    email: str
