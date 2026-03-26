import json
import sys
from pathlib import Path

from fastapi.openapi.utils import get_openapi

REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = REPO_ROOT / "backend"
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.main import app

CONTRACT_PATH = REPO_ROOT / "contracts" / "openapi.json"


def build_openapi() -> dict:
    return get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )


def main() -> None:
    spec = build_openapi()
    CONTRACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONTRACT_PATH.write_text(
        json.dumps(spec, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote OpenAPI contract to {CONTRACT_PATH}")


if __name__ == "__main__":
    main()
