from sqlalchemy import Engine, inspect, text

from app.core.ids import generate_public_id
from app.core.time import utc_now


def ensure_incident_team_fk(engine: Engine) -> None:
    inspector = inspect(engine)
    if "incidents" not in inspector.get_table_names():
        return

    incident_columns = {column["name"] for column in inspector.get_columns("incidents")}
    with engine.begin() as connection:
        if "team_id" not in incident_columns:
            connection.execute(text("ALTER TABLE incidents ADD COLUMN team_id INTEGER"))
            connection.execute(
                text(
                    "ALTER TABLE incidents "
                    "ADD CONSTRAINT fk_incidents_team_id "
                    "FOREIGN KEY (team_id) REFERENCES teams(id)"
                )
            )

        if "team" in incident_columns:
            connection.execute(text("ALTER TABLE incidents DROP COLUMN team"))


def ensure_public_ids(engine: Engine) -> None:
    inspector = inspect(engine)
    table_names = set(inspector.get_table_names())
    target_tables = {
        "teams",
        "users",
        "incidents",
        "team_memberships",
        "devices",
        "web_push_subscriptions",
    } & table_names
    if not target_tables:
        return

    with engine.begin() as connection:
        for table_name in sorted(target_tables):
            columns = {column["name"] for column in inspector.get_columns(table_name)}
            if "public_id" not in columns:
                connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN public_id VARCHAR(36)"))

            rows = connection.execute(text(f"SELECT id, public_id FROM {table_name}")).mappings().all()
            for row in rows:
                if row["public_id"]:
                    continue
                connection.execute(
                    text(f"UPDATE {table_name} SET public_id = :public_id WHERE id = :id"),
                    {"public_id": generate_public_id(), "id": row["id"]},
                )


def ensure_response_record_fields(engine: Engine) -> None:
    inspector = inspect(engine)
    if "responses" not in inspector.get_table_names():
        return

    response_columns = {column["name"] for column in inspector.get_columns("responses")}
    with engine.begin() as connection:
        if "user_id" not in response_columns:
            connection.execute(text("ALTER TABLE responses ADD COLUMN user_id INTEGER"))
        if "source" not in response_columns:
            connection.execute(text("ALTER TABLE responses ADD COLUMN source VARCHAR(50)"))
        if "updated_at" not in response_columns:
            connection.execute(text("ALTER TABLE responses ADD COLUMN updated_at TIMESTAMP"))
        if engine.dialect.name == "postgresql":
            if "name" in response_columns:
                connection.execute(text("ALTER TABLE responses ALTER COLUMN name DROP NOT NULL"))
            if "detail" in response_columns:
                connection.execute(text("ALTER TABLE responses ALTER COLUMN detail DROP NOT NULL"))

        now_value = utc_now()
        if "user_id" in response_columns or "user_id" not in response_columns:
            connection.execute(
                text(
                    "UPDATE responses SET updated_at = :updated_at "
                    "WHERE updated_at IS NULL"
                ),
                {"updated_at": now_value},
            )
            connection.execute(
                text(
                    "UPDATE responses SET source = 'legacy' "
                    "WHERE source IS NULL OR source = ''"
                )
            )
