from pydantic import BaseModel


class GoogleAuthRequest(BaseModel):
    id_token: str
    requested_role: str


class AuthUserRead(BaseModel):
    name: str
    initials: str
    role: str
    email: str
