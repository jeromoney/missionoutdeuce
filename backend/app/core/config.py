import os
from pathlib import Path

from pydantic import AliasChoices
from pydantic import field_validator
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


BACKEND_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_EXTERNAL_ENV_FILE = BACKEND_ROOT.parent / "Secrets" / "missionout-backend.env"
ENV_FILE_CANDIDATES: list[str] = []

env_file_override = os.getenv("MISSIONOUT_ENV_FILE")
if env_file_override:
    ENV_FILE_CANDIDATES.append(env_file_override)
elif DEFAULT_EXTERNAL_ENV_FILE.exists():
    ENV_FILE_CANDIDATES.append(str(DEFAULT_EXTERNAL_ENV_FILE))

ENV_FILE_CANDIDATES.append(".env")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=tuple(ENV_FILE_CANDIDATES),
        env_file_encoding="utf-8",
        extra="ignore",
        enable_decoding=False,
    )

    app_name: str = "MissionOut API"
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/missionout"
    api_host: str = "0.0.0.0"
    api_port: int = Field(default=8000, validation_alias=AliasChoices("API_PORT", "PORT"))
    debug: bool = False
    google_client_id: str | None = None
    allowed_origins: list[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ]
    allowed_origin_regex: str = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: str) -> str:
        if isinstance(value, str) and value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+psycopg://", 1)
        if isinstance(value, str) and value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+psycopg://", 1)
        return value

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def normalize_allowed_origins(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value


settings = Settings()
