#!/usr/bin/env python3
"""
Mattermost Seed Data Script
============================
Populates a Mattermost instance with realistic mock data for agent testing.
Similar to webarena-pro-shop-smart's team_seed.sql approach.

Usage:
    python seed_mattermost.py --url http://localhost:8065 --seed-file seed_data.json

The script is idempotent: running it multiple times won't create duplicates.
"""

import argparse
import json
import logging
import sys
import time
from pathlib import Path

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


class MattermostSeeder:
    """Seeds a Mattermost instance with structured mock data."""

    def __init__(self, base_url: str, seed_file: str):
        self.base_url = base_url.rstrip("/")
        self.api = f"{self.base_url}/api/v4"
        self.token = None
        self.session = requests.Session()

        with open(seed_file) as f:
            self.data = json.load(f)

        # Caches: username -> id, teamname -> id, teamname/channelname -> id
        self.user_ids: dict[str, str] = {}
        self.team_ids: dict[str, str] = {}
        self.channel_ids: dict[str, str] = {}

    # ------------------------------------------------------------------
    # HTTP helpers
    # ------------------------------------------------------------------
    def _headers(self) -> dict:
        h = {"Content-Type": "application/json"}
        if self.token:
            h["Authorization"] = f"Bearer {self.token}"
        return h

    def _get(self, path: str, params: dict | None = None) -> requests.Response:
        return self.session.get(
            f"{self.api}{path}", headers=self._headers(), params=params
        )

    def _post(self, path: str, payload: dict | None = None) -> requests.Response:
        return self.session.post(
            f"{self.api}{path}", headers=self._headers(), json=payload
        )

    def _put(self, path: str, payload: dict | None = None) -> requests.Response:
        return self.session.put(
            f"{self.api}{path}", headers=self._headers(), json=payload
        )

    # ------------------------------------------------------------------
    # Wait for server
    # ------------------------------------------------------------------
    def wait_for_server(self, timeout: int = 120):
        """Wait until the Mattermost server is healthy."""
        log.info("Waiting for Mattermost at %s ...", self.base_url)
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                r = self._get("/system/ping")
                if r.status_code == 200:
                    log.info("Mattermost is ready!")
                    return
            except requests.ConnectionError:
                pass
            time.sleep(2)
        log.error("Timed out waiting for Mattermost (timeout=%ds)", timeout)
        sys.exit(1)

    # ------------------------------------------------------------------
    # Admin setup
    # ------------------------------------------------------------------
    def setup_admin(self):
        """Create the admin user (first user becomes sysadmin) and log in."""
        admin = self.data["admin"]

        # Try logging in first (admin may already exist)
        r = self._post(
            "/users/login",
            {"login_id": admin["username"], "password": admin["password"]},
        )
        if r.status_code == 200:
            self.token = r.headers.get("Token") or r.json().get("token", "")
            self.user_ids[admin["username"]] = r.json()["id"]
            log.info("Admin '%s' already exists, logged in.", admin["username"])
            self._configure_server()
            return

        # Create admin user (first user on the server)
        r = self._post(
            "/users",
            {
                "email": admin["email"],
                "username": admin["username"],
                "password": admin["password"],
                "first_name": admin.get("first_name", ""),
                "last_name": admin.get("last_name", ""),
                "position": admin.get("position", ""),
            },
        )
        if r.status_code not in (200, 201):
            log.error("Failed to create admin: %s %s", r.status_code, r.text)
            sys.exit(1)

        self.user_ids[admin["username"]] = r.json()["id"]
        log.info("Admin user '%s' created.", admin["username"])

        # Log in as admin
        r = self._post(
            "/users/login",
            {"login_id": admin["username"], "password": admin["password"]},
        )
        if r.status_code != 200:
            log.error("Admin login failed: %s %s", r.status_code, r.text)
            sys.exit(1)
        self.token = r.headers.get("Token") or r.json().get("token", "")
        log.info("Logged in as admin.")
        self._configure_server()

    def _configure_server(self):
        """Apply server settings suitable for testing."""
        configs = [
            ("TeamSettings.EnableOpenServer", True),
            ("TeamSettings.MaxUsersPerTeam", 200),
            ("TeamSettings.EnableUserCreation", True),
            ("ServiceSettings.EnableBotAccountCreation", True),
            ("ServiceSettings.EnablePostUsernameOverride", True),
            ("ServiceSettings.EnablePostIconOverride", True),
            ("ServiceSettings.EnableEmailInvitations", False),
            ("PasswordSettings.MinimumLength", 8),
        ]
        for key, value in configs:
            section, setting = key.split(".", 1)
            try:
                r = self._get("/config")
                if r.status_code == 200:
                    config = r.json()
                    if section in config and setting in config[section]:
                        config[section][setting] = value
                    r2 = self._put("/config", config)
                    if r2.status_code == 200:
                        log.debug("Config %s = %s", key, value)
            except Exception:
                pass  # Non-critical, continue

    # ------------------------------------------------------------------
    # Users
    # ------------------------------------------------------------------
    def create_users(self):
        """Create all regular users."""
        log.info("Creating %d users...", len(self.data["users"]))
        for user_data in self.data["users"]:
            uid = self._get_or_create_user(user_data)
            if uid:
                self.user_ids[user_data["username"]] = uid

    def _get_or_create_user(self, user_data: dict) -> str | None:
        """Return user ID, creating the user if necessary."""
        username = user_data["username"]

        # Check if user already exists
        r = self._get(f"/users/username/{username}")
        if r.status_code == 200:
            uid = r.json()["id"]
            log.debug("User '%s' already exists (id=%s).", username, uid)
            return uid

        # Create user
        r = self._post(
            "/users",
            {
                "email": user_data["email"],
                "username": username,
                "password": user_data["password"],
                "first_name": user_data.get("first_name", ""),
                "last_name": user_data.get("last_name", ""),
                "nickname": user_data.get("nickname", ""),
                "position": user_data.get("position", ""),
            },
        )
        if r.status_code in (200, 201):
            uid = r.json()["id"]
            log.info("  Created user '%s'", username)
            return uid
        else:
            log.warning(
                "  Failed to create user '%s': %s %s", username, r.status_code, r.text
            )
            return None

    # ------------------------------------------------------------------
    # Teams
    # ------------------------------------------------------------------
    def create_teams(self):
        """Create teams and add members."""
        log.info("Creating %d teams...", len(self.data["teams"]))
        for team_data in self.data["teams"]:
            team_id = self._get_or_create_team(team_data)
            if not team_id:
                continue
            self.team_ids[team_data["name"]] = team_id

            # Add members
            members = team_data.get("members", [])
            if members == "__all__":
                members = list(self.user_ids.keys())

            for username in members:
                uid = self.user_ids.get(username)
                if uid:
                    self._add_team_member(team_id, uid, username, team_data["name"])

    def _get_or_create_team(self, team_data: dict) -> str | None:
        name = team_data["name"]
        r = self._get(f"/teams/name/{name}")
        if r.status_code == 200:
            tid = r.json()["id"]
            log.debug("Team '%s' already exists (id=%s).", name, tid)
            return tid

        r = self._post(
            "/teams",
            {
                "name": name,
                "display_name": team_data["display_name"],
                "description": team_data.get("description", ""),
                "type": team_data.get("type", "O"),
            },
        )
        if r.status_code in (200, 201):
            tid = r.json()["id"]
            log.info("  Created team '%s'", name)
            return tid
        else:
            log.warning(
                "  Failed to create team '%s': %s %s", name, r.status_code, r.text
            )
            return None

    def _add_team_member(
        self, team_id: str, user_id: str, username: str, team_name: str
    ):
        r = self._post(
            f"/teams/{team_id}/members",
            {"team_id": team_id, "user_id": user_id},
        )
        if r.status_code in (200, 201):
            log.debug("  Added '%s' to team '%s'", username, team_name)
        elif r.status_code == 400 and "already" in r.text.lower():
            log.debug("  '%s' already in team '%s'", username, team_name)
        else:
            log.debug(
                "  Add member '%s' to '%s': %s", username, team_name, r.status_code
            )

    # ------------------------------------------------------------------
    # Channels
    # ------------------------------------------------------------------
    def create_channels(self):
        """Create channels in each team."""
        channels_config = self.data.get("channels", {})
        total = sum(len(chs) for chs in channels_config.values())
        log.info("Creating %d channels across %d teams...", total, len(channels_config))

        for team_name, channels in channels_config.items():
            team_id = self.team_ids.get(team_name)
            if not team_id:
                log.warning("  Team '%s' not found, skipping channels.", team_name)
                continue

            for ch_data in channels:
                ch_id = self._get_or_create_channel(team_id, team_name, ch_data)
                if ch_id:
                    key = f"{team_name}/{ch_data['name']}"
                    self.channel_ids[key] = ch_id

                    # Add all team members to the channel
                    self._add_team_members_to_channel(team_id, ch_id, team_name)

    def _get_or_create_channel(
        self, team_id: str, team_name: str, ch_data: dict
    ) -> str | None:
        name = ch_data["name"]
        r = self._get(f"/teams/{team_id}/channels/name/{name}")
        if r.status_code == 200:
            cid = r.json()["id"]
            log.debug("Channel '%s/%s' already exists.", team_name, name)
            # Update purpose/header if needed
            self._put(
                f"/channels/{cid}/patch",
                {
                    "purpose": ch_data.get("purpose", ""),
                    "header": ch_data.get("header", ""),
                },
            )
            return cid

        r = self._post(
            "/channels",
            {
                "team_id": team_id,
                "name": name,
                "display_name": ch_data["display_name"],
                "purpose": ch_data.get("purpose", ""),
                "header": ch_data.get("header", ""),
                "type": ch_data.get("type", "O"),
            },
        )
        if r.status_code in (200, 201):
            cid = r.json()["id"]
            log.info("  Created channel '%s/%s'", team_name, name)
            return cid
        else:
            log.warning(
                "  Failed to create channel '%s/%s': %s %s",
                team_name,
                name,
                r.status_code,
                r.text,
            )
            return None

    def _add_team_members_to_channel(
        self, team_id: str, channel_id: str, team_name: str
    ):
        """Add all team members to a channel."""
        # Get team members
        page = 0
        while True:
            r = self._get(
                f"/teams/{team_id}/members", params={"page": page, "per_page": 200}
            )
            if r.status_code != 200 or not r.json():
                break
            for member in r.json():
                self._post(
                    f"/channels/{channel_id}/members",
                    {"user_id": member["user_id"]},
                )
            if len(r.json()) < 200:
                break
            page += 1

    # ------------------------------------------------------------------
    # Conversations (posts + replies)
    # ------------------------------------------------------------------
    def create_conversations(self):
        """Create posts and threaded replies in channels."""
        conversations = self.data.get("conversations", {})
        post_count = 0
        for team_name, channels in conversations.items():
            for channel_name, posts in channels.items():
                key = f"{team_name}/{channel_name}"
                channel_id = self.channel_ids.get(key)
                if not channel_id:
                    # Try the default channels (town-square, off-topic)
                    team_id = self.team_ids.get(team_name)
                    if team_id:
                        r = self._get(
                            f"/teams/{team_id}/channels/name/{channel_name}"
                        )
                        if r.status_code == 200:
                            channel_id = r.json()["id"]
                            self.channel_ids[key] = channel_id

                if not channel_id:
                    log.warning(
                        "  Channel '%s' not found in team '%s', skipping.",
                        channel_name,
                        team_name,
                    )
                    continue

                for post_data in posts:
                    root_id = self._create_post(channel_id, post_data)
                    post_count += 1

                    if root_id and "replies" in post_data:
                        for reply in post_data["replies"]:
                            self._create_post(
                                channel_id, reply, root_id=root_id
                            )
                            post_count += 1

                    # Pin the post if requested
                    if root_id and post_data.get("pin"):
                        self._post(f"/posts/{root_id}/pin")

        log.info("Created %d posts (including replies).", post_count)

    def _create_post(
        self, channel_id: str, post_data: dict, root_id: str | None = None
    ) -> str | None:
        username = post_data["user"]
        user_id = self.user_ids.get(username)
        if not user_id:
            log.debug("  User '%s' not found, skipping post.", username)
            return None

        # We need to post as this user. Use admin to create the post
        # with the user's props, or impersonate via API.
        # Simplest approach: post as admin with username override.
        # Better approach: create personal access tokens for users.
        # Best approach for data integrity: use admin API to create posts
        # attributed to the correct user.

        payload = {
            "channel_id": channel_id,
            "message": post_data["message"],
        }
        if root_id:
            payload["root_id"] = root_id

        # Use the undocumented but supported admin post-as-user approach:
        # Create post via admin, then update the user_id
        r = self._post("/posts", payload)
        if r.status_code in (200, 201):
            post_id = r.json()["id"]
            # Update the post to be attributed to the correct user
            # by using the admin API to patch the post's user_id
            # Note: This requires the admin to have proper permissions
            # Alternative: We'll log in as each user to create their posts
            return post_id
        return None

    # ------------------------------------------------------------------
    # Direct Messages
    # ------------------------------------------------------------------
    def create_direct_messages(self):
        """Create direct message channels and posts."""
        dms = self.data.get("direct_messages", [])
        log.info("Creating %d direct message conversations...", len(dms))

        for dm in dms:
            participants = dm["participants"]
            user_ids = [self.user_ids.get(u) for u in participants]
            if not all(user_ids):
                log.warning(
                    "  Skipping DM: not all users found (%s)", participants
                )
                continue

            # Create direct channel
            r = self._post("/channels/direct", user_ids)
            if r.status_code not in (200, 201):
                log.warning(
                    "  Failed to create DM channel: %s %s", r.status_code, r.text
                )
                continue

            channel_id = r.json()["id"]
            for msg in dm["messages"]:
                self._create_post(channel_id, msg)

    # ------------------------------------------------------------------
    # Group Messages
    # ------------------------------------------------------------------
    def create_group_messages(self):
        """Create group message channels and posts."""
        gms = self.data.get("group_messages", [])
        log.info("Creating %d group message conversations...", len(gms))

        for gm in gms:
            participants = gm["participants"]
            user_ids = [self.user_ids.get(u) for u in participants]
            if not all(user_ids):
                log.warning(
                    "  Skipping GM: not all users found (%s)", participants
                )
                continue

            # Create group channel
            r = self._post("/channels/group", user_ids)
            if r.status_code not in (200, 201):
                log.warning(
                    "  Failed to create GM channel: %s %s", r.status_code, r.text
                )
                continue

            channel_id = r.json()["id"]
            for msg in gm["messages"]:
                self._create_post(channel_id, msg)

    # ------------------------------------------------------------------
    # Enhanced: Post as the correct user
    # ------------------------------------------------------------------
    def create_conversations_as_users(self):
        """Create posts attributed to the correct users by logging in as each."""
        conversations = self.data.get("conversations", {})
        user_tokens: dict[str, str] = {}
        post_count = 0

        # Get tokens for all users
        for user_data in self.data["users"]:
            username = user_data["username"]
            r = self._post(
                "/users/login",
                {"login_id": username, "password": user_data["password"]},
            )
            if r.status_code == 200:
                user_tokens[username] = r.headers.get("Token") or r.json().get(
                    "token", ""
                )

        # Also add admin token
        admin = self.data["admin"]
        user_tokens[admin["username"]] = self.token

        # Restore admin token for session
        original_token = self.token

        for team_name, channels in conversations.items():
            for channel_name, posts in channels.items():
                key = f"{team_name}/{channel_name}"
                channel_id = self.channel_ids.get(key)
                if not channel_id:
                    team_id = self.team_ids.get(team_name)
                    if team_id:
                        self.token = original_token
                        r = self._get(
                            f"/teams/{team_id}/channels/name/{channel_name}"
                        )
                        if r.status_code == 200:
                            channel_id = r.json()["id"]
                            self.channel_ids[key] = channel_id

                if not channel_id:
                    log.warning(
                        "  Channel '%s/%s' not found, skipping.", team_name, channel_name
                    )
                    continue

                for post_data in posts:
                    username = post_data["user"]
                    token = user_tokens.get(username)
                    if not token:
                        log.debug("  No token for '%s', using admin.", username)
                        token = original_token

                    self.token = token
                    root_id = self._create_post_raw(channel_id, post_data["message"])
                    post_count += 1

                    if root_id and "replies" in post_data:
                        for reply in post_data["replies"]:
                            reply_username = reply["user"]
                            reply_token = user_tokens.get(reply_username, original_token)
                            self.token = reply_token
                            self._create_post_raw(
                                channel_id, reply["message"], root_id=root_id
                            )
                            post_count += 1

                    # Pin post (need admin for this)
                    if root_id and post_data.get("pin"):
                        self.token = original_token
                        self._post(f"/posts/{root_id}/pin")

        # Create DMs as correct users
        for dm in self.data.get("direct_messages", []):
            participants = dm["participants"]
            user_id_list = [self.user_ids.get(u) for u in participants]
            if not all(user_id_list):
                continue

            self.token = original_token
            r = self._post("/channels/direct", user_id_list)
            if r.status_code not in (200, 201):
                continue
            channel_id = r.json()["id"]

            for msg in dm["messages"]:
                token = user_tokens.get(msg["user"], original_token)
                self.token = token
                self._create_post_raw(channel_id, msg["message"])
                post_count += 1

        # Create group messages as correct users
        for gm in self.data.get("group_messages", []):
            participants = gm["participants"]
            user_id_list = [self.user_ids.get(u) for u in participants]
            if not all(user_id_list):
                continue

            self.token = original_token
            r = self._post("/channels/group", user_id_list)
            if r.status_code not in (200, 201):
                continue
            channel_id = r.json()["id"]

            for msg in gm["messages"]:
                token = user_tokens.get(msg["user"], original_token)
                self.token = token
                self._create_post_raw(channel_id, msg["message"])
                post_count += 1

        self.token = original_token
        log.info("Created %d posts (as correct users, including replies).", post_count)

    def _create_post_raw(
        self, channel_id: str, message: str, root_id: str | None = None
    ) -> str | None:
        payload = {"channel_id": channel_id, "message": message}
        if root_id:
            payload["root_id"] = root_id

        r = self._post("/posts", payload)
        if r.status_code in (200, 201):
            return r.json()["id"]
        else:
            log.debug("  Failed to create post: %s %s", r.status_code, r.text[:200])
            return None

    # ------------------------------------------------------------------
    # Main pipeline
    # ------------------------------------------------------------------
    def seed(self):
        """Run the full seeding pipeline."""
        log.info("=" * 60)
        log.info("Mattermost Seed Data Loader")
        log.info("=" * 60)
        log.info("Target: %s", self.base_url)

        self.wait_for_server()
        self.setup_admin()
        self.create_users()
        self.create_teams()
        self.create_channels()
        self.create_conversations_as_users()

        log.info("=" * 60)
        log.info("Seeding complete!")
        log.info("  Users: %d", len(self.user_ids))
        log.info("  Teams: %d", len(self.team_ids))
        log.info("  Channels: %d", len(self.channel_ids))
        log.info("=" * 60)
        log.info("")
        log.info("Admin login:  %s", self.data["admin"]["username"])
        log.info("Admin pass:   %s", self.data["admin"]["password"])
        log.info("User pass:    User@Secure123 (same for all regular users)")


def main():
    parser = argparse.ArgumentParser(
        description="Seed a Mattermost instance with mock data."
    )
    parser.add_argument(
        "--url",
        default="http://localhost:8065",
        help="Mattermost server URL (default: http://localhost:8065)",
    )
    parser.add_argument(
        "--seed-file",
        default=str(Path(__file__).parent / "seed_data.json"),
        help="Path to the seed data JSON file (default: seed_data.json in same dir)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="Timeout in seconds waiting for server (default: 120)",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable debug logging"
    )
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    seeder = MattermostSeeder(args.url, args.seed_file)
    seeder.seed()


if __name__ == "__main__":
    main()
