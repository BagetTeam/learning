#!/usr/bin/env python3
"""
Script to generate .auth/metabase_admin_state.json for AgentLab tasks.
Run this after setup.py has completed Metabase first-time setup.
"""
import os
import json
import httpx
from dotenv import load_dotenv

load_dotenv()

METABASE_URL = os.getenv("METABASE_URL", "http://localhost:3000")
METABASE_USERNAME = os.getenv("METABASE_USERNAME", "admin@admin.com")
METABASE_PASSWORD = os.getenv("METABASE_PASSWORD", "apassword123")
AUTH_STATE_PATH = "./.auth/metabase_admin_state.json"

def get_session_token() -> str | None:
    """Log in to Metabase and return the session token."""
    try:
        response = httpx.post(
            f"{METABASE_URL}/api/session",
            json={"username": METABASE_USERNAME, "password": METABASE_PASSWORD},
            timeout=10,
        )
        response.raise_for_status()
        return response.json().get("id")
    except httpx.HTTPError as e:
        print(f"Login failed: {e}")
        return None

def save_auth_state(token: str):
    """Save the session token as a Playwright-compatible storage state file."""
    os.makedirs(os.path.dirname(AUTH_STATE_PATH), exist_ok=True)
    state = {
        "cookies": [{
            "name": "metabase.SESSION",
            "value": token,
            "domain": "localhost",
            "path": "/",
            "httpOnly": True,
            "secure": False,
            "sameSite": "Lax"
        }],
        "origins": []
    }
    with open(AUTH_STATE_PATH, "w") as f:
        json.dump(state, f, indent=2)
    print(f"Auth state saved to {AUTH_STATE_PATH}")

def main():
    print(f"Logging in to Metabase at {METABASE_URL} as {METABASE_USERNAME}...")
    token = get_session_token()
    if not token:
        print("Could not obtain session token. Is Metabase running and setup complete?")
        return
    print(f"Login successful. Session token: {token[:8]}...")
    save_auth_state(token)

if __name__ == "__main__":
    main()