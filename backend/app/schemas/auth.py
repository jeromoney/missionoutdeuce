from pydantic import BaseModel


# Keep these request and response shapes aligned with docs/api-contracts.md.
class GoogleAuthRequest(BaseModel):
    id_token: str
    requested_role: str


class AuthUserRead(BaseModel):
    name: str
    initials: str
    role: str
    email: str