from sqlalchemy import text

from fastapi import APIRouter

from app.db.session import engine
from app.schemas.meta import HealthRead


router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthRead)
def health_check():
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))

    return {"status": "ok", "database": "connected"}
