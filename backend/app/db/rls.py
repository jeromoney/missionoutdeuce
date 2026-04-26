"""Postgres Row-Level Security policy setup.

Applies the policy matrix from `docs/security.md`. Per-request session context
is primed by `app.api.deps.get_current_principal` via `SET LOCAL app.user_id`
and `SET LOCAL app.role`. Policies read these through the helper functions
defined below.

This module is a no-op on non-Postgres dialects so the SQLite test suite keeps
working. See TODO in `app/api/deps.py` for migrating local/dev to Postgres.
"""
from sqlalchemy import Engine, text


_HELPER_DDL = [
    """
    CREATE OR REPLACE FUNCTION app_current_user_id() RETURNS INT
    LANGUAGE SQL STABLE AS $$
        SELECT NULLIF(current_setting('app.user_id', true), '')::int
    $$
    """,
    """
    CREATE OR REPLACE FUNCTION app_current_role() RETURNS TEXT
    LANGUAGE SQL STABLE AS $$
        SELECT NULLIF(current_setting('app.role', true), '')
    $$
    """,
]


# Subquery returning team ids the current user belongs to.
_USER_TEAM_IDS_SQ = (
    "(SELECT tm.team_id FROM team_memberships tm "
    "WHERE tm.user_id = app_current_user_id())"
)

# Predicate: the current row's team_id is one the user belongs to.
_USER_TEAM_IDS = f"team_id IN {_USER_TEAM_IDS_SQ}"

# Predicate: the current row's user_id is a teammate of the current user.
_TEAMMATE_USER_IDS = (
    "user_id IN (SELECT tm2.user_id FROM team_memberships tm2 "
    f"WHERE tm2.team_id IN {_USER_TEAM_IDS_SQ})"
)


def _policy(name: str, table: str, op: str, *, using: str | None = None, check: str | None = None) -> list[str]:
    stmts = [f"DROP POLICY IF EXISTS {name} ON {table}"]
    clauses = [f"CREATE POLICY {name} ON {table} FOR {op}"]
    if using is not None:
        clauses.append(f"USING ({using})")
    if check is not None:
        clauses.append(f"WITH CHECK ({check})")
    stmts.append(" ".join(clauses))
    return stmts


def _incidents_policies() -> list[str]:
    admin_scope = f"app_current_role() = 'team_admin' AND {_USER_TEAM_IDS}"
    dispatcher_scope = f"app_current_role() = 'dispatcher' AND {_USER_TEAM_IDS}"
    responder_scope = f"app_current_role() = 'responder' AND {_USER_TEAM_IDS}"
    stmts = ["ALTER TABLE incidents ENABLE ROW LEVEL SECURITY"]
    stmts += _policy("incidents_admin_all", "incidents", "ALL", using=admin_scope, check=admin_scope)
    stmts += _policy("incidents_dispatcher_select", "incidents", "SELECT", using=dispatcher_scope)
    stmts += _policy("incidents_dispatcher_insert", "incidents", "INSERT", check=dispatcher_scope)
    stmts += _policy(
        "incidents_dispatcher_update", "incidents", "UPDATE",
        using=dispatcher_scope, check=dispatcher_scope,
    )
    stmts += _policy("incidents_responder_select", "incidents", "SELECT", using=responder_scope)
    return stmts


def _responses_policies() -> list[str]:
    # All roles: SIUD for incidents in their team.
    scope = (
        f"incident_id IN (SELECT i.id FROM incidents i WHERE i.team_id IN {_USER_TEAM_IDS_SQ})"
    )
    gate = "app_current_role() IN ('team_admin','dispatcher','responder')"
    condition = f"{gate} AND {scope}"
    stmts = ["ALTER TABLE responses ENABLE ROW LEVEL SECURITY"]
    stmts += _policy("responses_all", "responses", "ALL", using=condition, check=condition)
    return stmts


def _web_push_subscriptions_policies() -> list[str]:
    # admin/dispatcher: own team or own user.
    privileged_scope = (
        "app_current_role() IN ('team_admin','dispatcher') AND "
        f"(user_id = app_current_user_id() OR {_USER_TEAM_IDS})"
    )
    responder_scope = (
        "app_current_role() = 'responder' AND user_id = app_current_user_id()"
    )
    stmts = ["ALTER TABLE web_push_subscriptions ENABLE ROW LEVEL SECURITY"]
    stmts += _policy(
        "web_push_subscriptions_privileged_all", "web_push_subscriptions", "ALL",
        using=privileged_scope, check=privileged_scope,
    )
    stmts += _policy(
        "web_push_subscriptions_responder_all", "web_push_subscriptions", "ALL",
        using=responder_scope, check=responder_scope,
    )
    return stmts


def _devices_policies() -> list[str]:
    # admin/dispatcher: own user or teammate user.
    privileged_scope = (
        "app_current_role() IN ('team_admin','dispatcher') AND "
        f"(user_id = app_current_user_id() OR {_TEAMMATE_USER_IDS})"
    )
    responder_scope = (
        "app_current_role() = 'responder' AND user_id = app_current_user_id()"
    )
    stmts = ["ALTER TABLE devices ENABLE ROW LEVEL SECURITY"]
    stmts += _policy(
        "devices_privileged_all", "devices", "ALL",
        using=privileged_scope, check=privileged_scope,
    )
    stmts += _policy(
        "devices_responder_all", "devices", "ALL",
        using=responder_scope, check=responder_scope,
    )
    return stmts


def _delivery_events_policies() -> list[str]:
    # Matrix: admin/dispatcher S; responder none.
    # Schema lacks incident/team FK, so we gate by role only for now.
    # TODO(rls): tighten once delivery_events gains a team_id or incident_id FK.
    gate = "app_current_role() IN ('team_admin','dispatcher')"
    stmts = ["ALTER TABLE delivery_events ENABLE ROW LEVEL SECURITY"]
    stmts += _policy("delivery_events_privileged_select", "delivery_events", "SELECT", using=gate)
    return stmts


def _team_memberships_policies() -> list[str]:
    admin_scope = f"app_current_role() = 'team_admin' AND {_USER_TEAM_IDS}"
    reader_scope = (
        "app_current_role() IN ('dispatcher','responder') AND "
        f"{_USER_TEAM_IDS}"
    )
    stmts = ["ALTER TABLE team_memberships ENABLE ROW LEVEL SECURITY"]
    stmts += _policy(
        "team_memberships_admin_all", "team_memberships", "ALL",
        using=admin_scope, check=admin_scope,
    )
    stmts += _policy(
        "team_memberships_reader_select", "team_memberships", "SELECT",
        using=reader_scope,
    )
    return stmts


def _users_policies() -> list[str]:
    # users themselves don't carry team_id — scope via team_memberships.
    teammate = (
        "(id = app_current_user_id() OR id IN ("
        f"SELECT tm.user_id FROM team_memberships tm WHERE tm.team_id IN {_USER_TEAM_IDS_SQ}"
        "))"
    )
    admin_scope = f"app_current_role() = 'team_admin' AND {teammate}"
    reader_scope = f"app_current_role() IN ('dispatcher','responder') AND {teammate}"
    stmts = ["ALTER TABLE users ENABLE ROW LEVEL SECURITY"]
    stmts += _policy(
        "users_admin_all", "users", "ALL",
        using=admin_scope, check=admin_scope,
    )
    stmts += _policy("users_reader_select", "users", "SELECT", using=reader_scope)
    stmts += _policy(
        "users_reader_update", "users", "UPDATE",
        using=reader_scope, check=reader_scope,
    )
    return stmts


def _teams_policies() -> list[str]:
    scope = f"id IN {_USER_TEAM_IDS_SQ}"
    gate = "app_current_role() IN ('team_admin','dispatcher','responder')"
    condition = f"{gate} AND {scope}"
    stmts = ["ALTER TABLE teams ENABLE ROW LEVEL SECURITY"]
    stmts += _policy("teams_select", "teams", "SELECT", using=condition)
    return stmts


def _incident_events_policies() -> list[str]:
    # All three roles may read events for incidents in their team.
    scope = (
        f"incident_id IN (SELECT i.id FROM incidents i WHERE i.team_id IN {_USER_TEAM_IDS_SQ})"
    )
    gate = "app_current_role() IN ('team_admin','dispatcher','responder')"
    condition = f"{gate} AND {scope}"
    stmts = ["ALTER TABLE incident_events ENABLE ROW LEVEL SECURITY"]
    stmts += _policy("incident_events_select", "incident_events", "SELECT", using=condition)
    return stmts


def _push_deliveries_policies() -> list[str]:
    # Worker-facing queue: only privileged team members may inspect rows.
    # INSERT happens inside backend-owned transactions that bypass RLS, so no
    # client INSERT/UPDATE/DELETE policies are issued here.
    scope = (
        f"incident_id IN (SELECT i.id FROM incidents i WHERE i.team_id IN {_USER_TEAM_IDS_SQ})"
    )
    gate = "app_current_role() IN ('team_admin','dispatcher')"
    condition = f"{gate} AND {scope}"
    stmts = ["ALTER TABLE push_deliveries ENABLE ROW LEVEL SECURITY"]
    stmts += _policy("push_deliveries_privileged_select", "push_deliveries", "SELECT", using=condition)
    return stmts


def _token_tables_policies() -> list[str]:
    # Backend-only tables: enable RLS with no policies → non-owner sessions are
    # fully blocked. Backend startup/token flows run as the DB owner.
    stmts = []
    for table in ("email_link_tokens", "email_code_tokens"):
        stmts.append(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY")
    return stmts


def apply_rls_policies(engine: Engine) -> None:
    if engine.dialect.name != "postgresql":
        return

    statements: list[str] = []
    statements.extend(_HELPER_DDL)
    statements.extend(_incidents_policies())
    statements.extend(_responses_policies())
    statements.extend(_incident_events_policies())
    statements.extend(_push_deliveries_policies())
    statements.extend(_web_push_subscriptions_policies())
    statements.extend(_devices_policies())
    statements.extend(_delivery_events_policies())
    statements.extend(_team_memberships_policies())
    statements.extend(_users_policies())
    statements.extend(_teams_policies())
    statements.extend(_token_tables_policies())

    # email_link_tokens may not exist yet (no corresponding SQLAlchemy model
    # today), so skip it if absent.
    from sqlalchemy import inspect as sa_inspect
    inspector = sa_inspect(engine)
    existing_tables = set(inspector.get_table_names())

    with engine.begin() as connection:
        for statement in statements:
            # Skip statements that target tables not yet created.
            stripped = statement.strip()
            missing = False
            for table in (
                "email_link_tokens",
                "email_code_tokens",
                "delivery_events",
                "team_memberships",
                "incident_events",
                "push_deliveries",
                "incidents",
                "responses",
                "web_push_subscriptions",
                "devices",
                "users",
                "teams",
            ):
                if table in stripped and table not in existing_tables:
                    missing = True
                    break
            if missing:
                continue
            connection.execute(text(stripped))
