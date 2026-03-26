from pydantic import BaseModel


# Keep these request and response shapes aligned with contracts/openapi.json.
class GoogleAuthRequest(BaseModel):
    id_token: str
    requested_client: str


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
