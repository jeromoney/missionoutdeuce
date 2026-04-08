from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import auth, devices, events, health, incidents, team_management
from app.core.config import settings
from app.db.base import Base
from app.db.bootstrap import ensure_incident_team_fk, ensure_public_ids
from app.db.session import engine
from app.models import (
    DeliveryEvent,
    Device,
    EmailCodeToken,
    Incident,
    ResponseRecord,
    Team,
    TeamMembership,
    User,
    WebPushSubscription,
)
from app.schemas.meta import RootRead


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    ensure_incident_team_fk(engine)
    ensure_public_ids(engine)
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description=(
        "MissionOut API contract for dispatcher, team admin, and responder "
        "clients. The exported OpenAPI document in contracts/openapi.json is "
        "the cross-stack source of truth."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_origin_regex=settings.allowed_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(health.router)
app.include_router(incidents.router)
app.include_router(events.router)
app.include_router(devices.router)
app.include_router(team_management.router)


@app.get("/", tags=["meta"], response_model=RootRead)
def root():
    return {
        "name": settings.app_name,
        "status": "ok",
        "health": "/health",
        "docs": "/docs",
    }
