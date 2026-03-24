#!/usr/bin/env python3
"""
Combined setup script for Metabase.
Runs all setup steps: add database, create SQL query, create dashboard.
"""

import os
import sys

import httpx
from dotenv import load_dotenv

load_dotenv()

METABASE_URL = os.getenv("METABASE_URL", "http://localhost:3000")
METABASE_USERNAME = os.getenv("METABASE_USERNAME", "admin@admin.com")
METABASE_PASSWORD = os.getenv("METABASE_PASSWORD", "apassword123")

DATABASE_NAME = "my-db"
DATABASE_CONFIG = {
    "name": DATABASE_NAME,
    "engine": "postgres",
    "details": {
        "host": "my-db",
        "port": 5432,
        "dbname": "sample_data",
        "user": "sample",
        "password": "sample",
        "ssl": False,
    },
}

SQL_QUERY_NAME = "Revenue by Category"
SQL_QUERY = """
SELECT 
    p.category,
    COUNT(DISTINCT o.id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.subtotal)::numeric, 2) AS total_revenue,
    ROUND(AVG(oi.subtotal)::numeric, 2) AS avg_order_value
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'completed')
GROUP BY p.category
ORDER BY total_revenue DESC
""".strip()

SIMPLE_QUESTION_NAME = "Orders by Status"
DASHBOARD_NAME = "Sales Overview"


class MetabaseClient:
    """Simple Metabase API client."""

    def __init__(self, url: str, username: str, password: str):
        self.url = url
        self.token: str | None = None
        self.username = username
        self.password = password

    def authenticate(self) -> bool:
        """Authenticate and store session token."""
        try:
            response = httpx.post(
                f"{self.url}/api/session",
                json={"username": self.username, "password": self.password},
                timeout=10,
            )
            response.raise_for_status()
            self.token = response.json().get("id")
            return True
        except httpx.HTTPError as e:
            print(f"Failed to authenticate: {e}")
            return False

    def _headers(self) -> dict:
        return {"X-Metabase-Session": self.token}

    def get_databases(self) -> list[dict]:
        response = httpx.get(
            f"{self.url}/api/database", headers=self._headers(), timeout=10
        )
        response.raise_for_status()
        return response.json().get("data", [])

    def get_database_id(self, name: str) -> int | None:
        for db in self.get_databases():
            if db.get("name") == name:
                return db.get("id")
        return None

    def add_database(self, config: dict) -> int | None:
        response = httpx.post(
            f"{self.url}/api/database",
            headers=self._headers(),
            json=config,
            timeout=30,
        )
        response.raise_for_status()
        return response.json().get("id")

    def get_cards(self) -> list[dict]:
        response = httpx.get(
            f"{self.url}/api/card", headers=self._headers(), timeout=10
        )
        response.raise_for_status()
        return response.json()

    def get_card_id(self, name: str) -> int | None:
        for card in self.get_cards():
            if card.get("name") == name:
                return card.get("id")
        return None

    def create_card(self, config: dict) -> int | None:
        response = httpx.post(
            f"{self.url}/api/card",
            headers=self._headers(),
            json=config,
            timeout=30,
        )
        response.raise_for_status()
        return response.json().get("id")

    def get_dashboards(self) -> list[dict]:
        response = httpx.get(
            f"{self.url}/api/dashboard", headers=self._headers(), timeout=10
        )
        response.raise_for_status()
        return response.json()

    def get_dashboard_id(self, name: str) -> int | None:
        for d in self.get_dashboards():
            if d.get("name") == name:
                return d.get("id")
        return None

    def create_dashboard(self, config: dict) -> int | None:
        response = httpx.post(
            f"{self.url}/api/dashboard",
            headers=self._headers(),
            json=config,
            timeout=30,
        )
        response.raise_for_status()
        return response.json().get("id")

    def update_dashboard(self, dashboard_id: int, config: dict) -> bool:
        response = httpx.put(
            f"{self.url}/api/dashboard/{dashboard_id}",
            headers=self._headers(),
            json=config,
            timeout=30,
        )
        response.raise_for_status()
        return True

    def get_table_id(self, database_id: int, table_name: str) -> int | None:
        response = httpx.get(
            f"{self.url}/api/database/{database_id}/metadata",
            headers=self._headers(),
            timeout=30,
        )
        response.raise_for_status()
        for table in response.json().get("tables", []):
            if table.get("name") == table_name:
                return table.get("id")
        return None

    def get_field_id(self, table_id: int, field_name: str) -> int | None:
        response = httpx.get(
            f"{self.url}/api/table/{table_id}/query_metadata",
            headers=self._headers(),
            timeout=10,
        )
        response.raise_for_status()
        for field in response.json().get("fields", []):
            if field.get("name") == field_name:
                return field.get("id")
        return None


def step_add_database(client: MetabaseClient) -> int:
    """Step 1: Add database if not exists."""
    print("Step 1/3: Adding database...")

    db_id = client.get_database_id(DATABASE_NAME)
    if db_id:
        print(f"  Database '{DATABASE_NAME}' already exists (ID: {db_id})")
        return db_id

    db_id = client.add_database(DATABASE_CONFIG)
    print(f"  Created database '{DATABASE_NAME}' with ID: {db_id}")
    return db_id


def step_add_sql_query(client: MetabaseClient, database_id: int) -> int:
    """Step 2: Add SQL query if not exists."""
    print("Step 2/3: Creating SQL query...")

    card_id = client.get_card_id(SQL_QUERY_NAME)
    if card_id:
        print(f"  SQL question '{SQL_QUERY_NAME}' already exists (ID: {card_id})")
        return card_id

    config = {
        "name": SQL_QUERY_NAME,
        "display": "table",
        "visualization_settings": {
            "table.pivot": False,
            "column_settings": {
                '["name","total_revenue"]': {"number_style": "currency", "currency": "USD"},
                '["name","avg_order_value"]': {"number_style": "currency", "currency": "USD"},
            },
        },
        "dataset_query": {
            "database": database_id,
            "type": "native",
            "native": {"query": SQL_QUERY, "template-tags": {}},
        },
    }

    card_id = client.create_card(config)
    print(f"  Created SQL question '{SQL_QUERY_NAME}' with ID: {card_id}")
    return card_id


def step_add_dashboard(
    client: MetabaseClient, database_id: int, sql_card_id: int
) -> int:
    """Step 3: Add dashboard with questions."""
    print("Step 3/3: Creating dashboard...")

    # Check if dashboard exists
    dashboard_id = client.get_dashboard_id(DASHBOARD_NAME)
    if dashboard_id:
        print(f"  Dashboard '{DASHBOARD_NAME}' already exists (ID: {dashboard_id})")
        return dashboard_id

    # Get or create simple question
    simple_card_id = client.get_card_id(SIMPLE_QUESTION_NAME)
    if simple_card_id:
        print(f"  Question '{SIMPLE_QUESTION_NAME}' already exists (ID: {simple_card_id})")
    else:
        table_id = client.get_table_id(database_id, "orders")
        if not table_id:
            raise RuntimeError("Could not find 'orders' table")

        field_id = client.get_field_id(table_id, "status")
        if not field_id:
            raise RuntimeError("Could not find 'status' field")

        config = {
            "name": SIMPLE_QUESTION_NAME,
            "display": "pie",
            "visualization_settings": {"pie.show_legend": True, "pie.show_total": True},
            "dataset_query": {
                "database": database_id,
                "type": "query",
                "query": {
                    "source-table": table_id,
                    "aggregation": [["count"]],
                    "breakout": [["field", field_id, None]],
                },
            },
        }
        simple_card_id = client.create_card(config)
        print(f"  Created question '{SIMPLE_QUESTION_NAME}' with ID: {simple_card_id}")

    # Create dashboard
    dashboard_id = client.create_dashboard({
        "name": DASHBOARD_NAME,
        "description": "Overview of sales metrics and order status",
    })
    print(f"  Created dashboard '{DASHBOARD_NAME}' with ID: {dashboard_id}")

    # Add cards to dashboard
    dashcards = [
        {
            "id": -1,
            "card_id": None,
            "row": 0,
            "col": 0,
            "size_x": 24,
            "size_y": 1,
            "visualization_settings": {
                "virtual_card": {
                    "name": None,
                    "display": "heading",
                    "visualization_settings": {},
                    "dataset_query": {},
                    "archived": False,
                },
                "text": "Sales Overview Dashboard",
            },
        },
        {
            "id": -2,
            "card_id": sql_card_id,
            "row": 1,
            "col": 0,
            "size_x": 12,
            "size_y": 8,
        },
        {
            "id": -3,
            "card_id": simple_card_id,
            "row": 1,
            "col": 12,
            "size_x": 12,
            "size_y": 8,
        },
    ]

    client.update_dashboard(dashboard_id, {"dashcards": dashcards})
    print("  Added header and questions to dashboard")

    return dashboard_id


def main():
    print("=" * 50)
    print("Metabase Setup")
    print("=" * 50)
    print(f"URL: {METABASE_URL}")
    print("")

    client = MetabaseClient(METABASE_URL, METABASE_USERNAME, METABASE_PASSWORD)

    if not client.authenticate():
        print("Could not authenticate with Metabase. Is it running?")
        sys.exit(1)
    print("Authenticated successfully.\n")

    try:
        database_id = step_add_database(client)
        print("")

        sql_card_id = step_add_sql_query(client, database_id)
        print("")

        dashboard_id = step_add_dashboard(client, database_id, sql_card_id)
        print("")

    except httpx.HTTPStatusError as e:
        print(f"API error: {e}")
        print(f"Response: {e.response.text}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

    print("=" * 50)
    print("Setup Complete!")
    print("=" * 50)
    print(f"Dashboard: {METABASE_URL}/dashboard/{dashboard_id}")


if __name__ == "__main__":
    main()
