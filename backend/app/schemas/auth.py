from typing import Literal

from pydantic import BaseModel, model_validator


# Keep these request and response shapes aligned with contracts/openapi.json.
class GoogleAuthRequest(BaseModel):
    id_token: str | None = None
    access_token: str | None = None
    requested_client: Literal["responder", "dispatcher", "team_admin"]

    @model_validator(mode="after")
    def validate_token_present(self) -> "GoogleAuthRequest":
        if self.id_token or self.access_token:
            return self
        raise ValueError("Either id_token or access_token is required.")


class AuthTeamMembershipRead(BaseModel):
    team_id: int
    team_name: str
    roles: list[str]


class AuthUserRead(BaseModel):
    name: str
    initials: str
    global_permissions: list[str]
    team_memberships: list[AuthTeamMembershipRead]
    email: str
