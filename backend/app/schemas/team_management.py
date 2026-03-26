from datetime import datetime

from pydantic import BaseModel


class TeamMemberCreate(BaseModel):
    name: str
    email: str
    phone: str = ""
    roles: list[str]
    is_active: bool = True


class TeamMemberUpdate(BaseModel):
    roles: list[str] | None = None
    is_active: bool | None = None


class TeamMemberRead(BaseModel):
    id: int
    user_id: int
    team_id: int
    name: str
    email: str
    phone: str
    roles: list[str]
    is_active: bool
    granted_at: datetime
    revoked_at: datetime | None


class DeviceRead(BaseModel):
    id: int
    user_id: int
    user_name: str
    platform: str
    push_token: str
    last_seen: datetime
    is_active: bool
    is_verified: bool
