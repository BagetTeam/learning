CREDENTIALS = {
    "nextcloud": {
        "username": "agent1",
        "password": "agentpass",
    },
    "flight-search": {
        "passkey": "flyingagents",
    },
    "notion": {
        "username": "agent1",
        "password": "agentpass",
    },
}


def get_website_credentials(website: str) -> dict[str, str] | None:
    if isinstance(CREDENTIALS, dict):
        credentials = CREDENTIALS.get(website)
        return credentials if isinstance(credentials, dict) else None

    if isinstance(CREDENTIALS, list):
        for credentials_by_site in CREDENTIALS:
            if not isinstance(credentials_by_site, dict):
                continue
            credentials = credentials_by_site.get(website)
            if isinstance(credentials, dict):
                return credentials

    return None
