from pydantic import BaseModel


class AuthTeamMembershipRead(BaseModel):
    team_public_id: str
    team_name: str
    roles: list[str]


class AuthUserRead(BaseModel):
    public_id: str
    name: str
    initials: str
    global_permissions: list[str]
    team_memberships: list[AuthTeamMembershipRead]
    email: str
