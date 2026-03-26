import json
import sys
from pathlib import Path

from export_openapi import CONTRACT_PATH, build_openapi


def main() -> int:
    if not CONTRACT_PATH.exists():
        print(
            f"Missing contract file at {CONTRACT_PATH}. "
            "Run `python backend/scripts/export_openapi.py` first."
        )
        return 1

    expected = json.loads(
        json.dumps(build_openapi(), sort_keys=True)
    )
    actual = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))

    if actual != expected:
        print(
            "contracts/openapi.json is out of date. "
            "Run `python backend/scripts/export_openapi.py` and commit the result."
        )
        return 1

    print("OpenAPI contract is up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
