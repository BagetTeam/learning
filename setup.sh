#!/bin/bash
# Setup script for Metabase: first-time setup, database, questions, dashboards, and docs
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Metabase Setup ==="
echo ""

echo "Step 1/5: First-time setup (create admin user)..."
python "$SCRIPT_DIR/setup_scripts/setup_login.py"
echo ""

echo "Step 2/5: Adding database..."
python "$SCRIPT_DIR/setup_scripts/add_database.py"
echo ""

echo "Step 3/5: Creating SQL query..."
python "$SCRIPT_DIR/setup_scripts/add_sql_query.py"
echo ""

echo "Step 4/5: Creating Sales dashboard..."
python "$SCRIPT_DIR/setup_scripts/add_dashboard.py"
echo ""

echo "Step 5/5: Creating AgentLab documentation..."
python "$SCRIPT_DIR/setup_scripts/add_documentation.py"
echo ""

echo "=== Setup Complete ==="
