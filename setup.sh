#!/bin/bash
# Setup script for Metabase: adds database, creates questions and dashboard
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Metabase Setup ==="
echo ""

echo "Step 1/3: Adding database..."
python "$SCRIPT_DIR/setup_scripts/add_database.py"
echo ""

echo "Step 2/3: Creating SQL query..."
python "$SCRIPT_DIR/setup_scripts/add_sql_query.py"
echo ""

echo "Step 3/3: Creating dashboard..."
python "$SCRIPT_DIR/setup_scripts/add_dashboard.py"
echo ""

echo "=== Setup Complete ==="
