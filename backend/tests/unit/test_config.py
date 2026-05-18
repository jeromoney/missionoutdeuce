import pytest

from app.core.config import DEFAULT_EXTERNAL_ENV_FILE, Settings

pytestmark = pytest.mark.skipif(
    not DEFAULT_EXTERNAL_ENV_FILE.exists(),
    reason="secrets file not present — skipping env smoke test",
)


def test_settings_load_without_error():
    """Verify the secrets file is parseable and produces a valid Settings object."""
    s = Settings()
    assert s.database_url, "DATABASE_URL missing from env files"
