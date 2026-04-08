from datetime import datetime

from pydantic import BaseModel
from typing import Literal


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
    public_id: str
    user_public_id: str
    team_public_id: str
    name: str
    email: str
    phone: str
    roles: list[str]
    is_active: bool
    granted_at: datetime
    revoked_at: datetime | None


class DeviceRead(BaseModel):
    public_id: str
    user_public_id: str
    user_name: str
    platform: str
    push_token: str
    last_seen: datetime
    is_active: bool
    is_verified: bool


class WebPushKeys(BaseModel):
    p256dh: str
    auth: str


class WebPushSubscriptionCreate(BaseModel):
    endpoint: str
    keys: WebPushKeys
    user_agent: str = ""
    client: Literal["responder", "dispatcher", "team_admin"]
    team_public_id: str | None = None


class WebPushSubscriptionDelete(BaseModel):
    endpoint: str


class WebPushSubscriptionRead(BaseModel):
    public_id: str
    user_public_id: str
    team_public_id: str | None
    platform: Literal["web"] = "web"
    endpoint: str
    client: str
    last_seen: datetime
    is_active: bool


class WebPushPublicKeyRead(BaseModel):
    public_key: str
    subject: str
