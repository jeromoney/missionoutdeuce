from sqlalchemy import Engine, inspect, text


def ensure_incident_team_fk(engine: Engine) -> None:
    inspector = inspect(engine)
    if "incidents" not in inspector.get_table_names():
        return

    incident_columns = {column["name"] for column in inspector.get_columns("incidents")}
    if "team_id" in incident_columns:
        return

    with engine.begin() as connection:
        connection.execute(text("ALTER TABLE incidents ADD COLUMN team_id INTEGER"))
        connection.execute(
            text(
                "UPDATE incidents "
                "SET team_id = teams.id "
                "FROM teams "
                "WHERE incidents.team = teams.name"
            )
        )
        connection.execute(
            text(
                "ALTER TABLE incidents "
                "ADD CONSTRAINT fk_incidents_team_id "
                "FOREIGN KEY (team_id) REFERENCES teams(id)"
            )
        )
