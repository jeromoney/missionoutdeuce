"""Mint a Firebase custom token for the smoke-test user.

Prints the token to stdout so a shell script can capture it.

Android emulator (10.0.2.2 reaches the host machine's localhost):

    TOKEN=$(FIREBASE_CREDENTIALS_PATH=/Users/justinmatis/Documents/Secrets/firebase-service-account.json \\
        python backend/scripts/mint_test_token.py)

    flutter test integration_test/backend_smoke_test.dart \\
        --dart-define=API_BASE_URL=http://10.0.2.2:8000 \\
        --dart-define=TEST_FIREBASE_TOKEN=$TOKEN \\
        -d <android-emulator-id>

iOS simulator (localhost reaches the host directly):

    flutter test integration_test/backend_smoke_test.dart \\
        --dart-define=API_BASE_URL=http://localhost:8000 \\
        --dart-define=TEST_FIREBASE_TOKEN=$TOKEN \\
        -d <ios-simulator-id>

The backend must be running locally (python run.py) before executing the test.
The token is valid for 1 hour — re-run the script if it expires.
"""

import os
import sys

import firebase_admin
from firebase_admin import auth, credentials

_TEST_EMAIL = "justin.matis@gmail.com"


def main() -> None:
    creds_path = os.environ.get("FIREBASE_CREDENTIALS_PATH")
    if not creds_path:
        print("error: FIREBASE_CREDENTIALS_PATH is not set", file=sys.stderr)
        sys.exit(1)

    cred = credentials.Certificate(creds_path)
    firebase_admin.initialize_app(cred)

    user = auth.get_user_by_email(_TEST_EMAIL)
    token = auth.create_custom_token(user.uid)
    print(token.decode("utf-8"))


if __name__ == "__main__":
    main()
