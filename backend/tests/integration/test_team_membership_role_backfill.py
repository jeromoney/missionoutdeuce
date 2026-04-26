import json

from sqlalchemy import text

from app.db.bootstrap import ensure_team_membership_role, _pick_role


def test_pick_role_applies_precedence():
    assert _pick_role(["responder", "team_admin", "dispatcher"]) == "team_admin"
    assert _pick_role(["dispatcher", "responder"]) == "dispatcher"
    assert _pick_role(["responder"]) == "responder"
    assert _pick_role([]) == "responder"
    assert _pick_role(None) == "responder"


def test_pick_role_handles_json_string_input():
    # SQLAlchemy may hand raw JSON text through the DB-API cursor; the
    # backfill must accept both list and JSON-encoded string shapes.
    assert _pick_role(json.dumps(["team_admin"])) == "team_admin"
    assert _pick_role(json.dumps([])) == "responder"
    assert _pick_role("not-json") == "responder"


def test_ensure_team_membership_role_backfills_blank_rows(db_session):
    # Precondition: fresh schema created by the db_session fixture already
    # includes the `role` column. Clear it on the seeded memberships and
    # re-run the bootstrap to confirm it repopulates from `roles`.
    db_session.execute(
        text("INSERT INTO teams (name, is_active, public_id) VALUES (:name, 1, :pid)"),
        {"name": "Backfill Team", "pid": "backfill-team"},
    )
    team_id = db_session.execute(
        text("SELECT id FROM teams WHERE public_id = :pid"),
        {"pid": "backfill-team"},
    ).scalar()

    db_session.execute(
        text(
            "INSERT INTO users (name, email, phone, is_active, public_id) "
            "VALUES (:name, :email, '', 1, :pid)"
        ),
        {"name": "Backfill User", "email": "backfill@example.com", "pid": "backfill-user"},
    )
    user_id = db_session.execute(
        text("SELECT id FROM users WHERE public_id = :pid"),
        {"pid": "backfill-user"},
    ).scalar()

    db_session.execute(
        text(
            "INSERT INTO team_memberships "
            "(user_id, team_id, roles, role, public_id, granted_at) "
            "VALUES (:uid, :tid, :roles, NULL, :pid, :granted)"
        ),
        {
            "uid": user_id,
            "tid": team_id,
            "roles": json.dumps(["dispatcher", "responder"]),
            "pid": "backfill-membership",
            "granted": "2026-01-01 00:00:00",
        },
    )
    db_session.commit()

    ensure_team_membership_role(db_session.bind)

    row = db_session.execute(
        text(
            "SELECT role FROM team_memberships WHERE public_id = :pid"
        ),
        {"pid": "backfill-membership"},
    ).mappings().one()
    assert row["role"] == "dispatcher"
