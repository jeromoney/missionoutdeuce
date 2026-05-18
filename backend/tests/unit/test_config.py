import pytest

from app.core.config import DEFAULT_EXTERNAL_ENV_FILE, Settings

pytestmark = pytest.mark.skipif(
    not DEFAULT_EXTERNAL_ENV_FILE.exists(),
    reason="secrets file not present — skipping env smoke test",
)


def test_required_settings_are_loaded():
    s = Settings()
    assert s.google_client_id is not None, "GOOGLE_CLIENT_ID missing from env files"
    assert s.jwt_signing_key is not None, "JWT_SIGNING_KEY missing from env files"
