from uuid import uuid4


def generate_public_id() -> str:
    return str(uuid4())
