from sqlalchemy import text

from fastapi import APIRouter

from app.db.session import engine


router = APIRouter(tags=["health"])


@router.get("/health")
def health_check():
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))

    return {"status": "ok", "database": "connected"}
