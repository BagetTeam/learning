# Metabase Local Environment

A local Metabase environment with sample e-commerce data, automated setup scripts, and optional browser agent capabilities.

## Overview

This project provides:
- A Docker-based Metabase instance with PostgreSQL backend
- Sample e-commerce database with customers, products, orders, and reviews
- Automated setup scripts to configure Metabase with databases, questions, and dashboards

## Prerequisites

- **Docker** and **Docker Compose** installed
- **Python 3.11+** installed

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/webarena-pro.git
cd webarena-pro
```

### 2. Set Up Python Environment (Recommended)

Using a virtual environment is recommended to isolate dependencies:

```bash
# Create virtual environment
python -m venv venv

# Activate it
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate     # On Windows

# Install dependencies
pip install -e .
```

Alternatively, install dependencies globally:

```bash
pip install -e .
```

### 3. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

The default values should work out of the box:

```bash
METABASE_URL=http://localhost:3000
METABASE_USERNAME=admin@admin.com
METABASE_PASSWORD=apassword123
```

### 4. Start Docker Containers

Start Metabase and the sample database:

```bash
docker-compose up -d
```

This starts three containers:
- **metabase** - Metabase server on port 3000
- **postgres** - Metabase's internal database
- **my-db** - Sample e-commerce database on port 5433

Wait for Metabase to be ready (first startup takes 1-2 minutes):

```bash
# Check container status
docker-compose ps

# View Metabase logs
docker-compose logs -f metabase
```

Metabase is ready when you see: `Metabase Initialization COMPLETE`

### 5. Run the Setup Script

Run the automated setup to configure Metabase:

```bash
# Option 1: Single Python script (recommended)
python setup_scripts/setup_all.py

# Option 2: Shell script
./setup.sh
```

The setup script will:
1. **Create admin user** - Complete first-time Metabase setup
2. **Add database** - Connect the sample e-commerce database
3. **Create SQL query** - "Revenue by Category" analysis
4. **Create Sales dashboard** - "Sales Overview" with charts
5. **Create AgentLab documentation** - Interactive docs dashboard explaining AgentLab
6. **Save auth state** - Create `.auth/metabase_admin_state.json` for browser agent tasks

Example output:

```
==================================================
Metabase Setup
==================================================
URL: http://localhost:3000
Waiting for Metabase at http://localhost:3000...
Metabase is ready.

Step 1/6: Checking first-time setup...
  Creating admin user: admin@admin.com
  First-time setup completed successfully

Authenticated successfully.

Step 2/6: Adding database...
  Created database 'my-db' with ID: 2

Step 3/6: Creating SQL query...
  Created SQL question 'Revenue by Category' with ID: 1

Step 4/6: Creating Sales dashboard...
  Created question 'Orders by Status' with ID: 2
  Created dashboard 'Sales Overview' with ID: 1
  Added header and questions to dashboard

Step 5/6: Creating AgentLab documentation...
  Created dashboard 'AgentLab Documentation' with ID: 2
  Added 5 documentation sections

Step 6/6: Saving auth state for browser agent...
  Auth state saved to ./.auth/metabase_admin_state.json

==================================================
Setup Complete!
==================================================
Sales Dashboard: http://localhost:3000/dashboard/1
AgentLab Docs:   http://localhost:3000/dashboard/2
Auth State:      ./.auth/metabase_admin_state.json
```

### 6. Access Metabase

Open http://localhost:3000 and log in with:
- **Email:** `admin@admin.com`
- **Password:** `apassword123`

## Sample Data

The sample database (`my-db`) contains e-commerce data:

| Table | Description |
|-------|-------------|
| `people` | 30 customers with name, email, location |
| `products` | 30 products with category, vendor, price, rating |
| `orders` | 200 orders with status (pending, paid, shipped, completed, returned) |
| `order_items` | Order line items with quantity, price, discount |
| `reviews` | 80 product reviews with ratings |
| `order_summary` | View joining orders with customer and item data |

## Setup Scripts

Individual scripts are available in `setup_scripts/`:

| Script | Purpose |
|--------|---------|
| `setup_all.py` | All-in-one setup (recommended) |
| `setup_login.py` | First-time Metabase setup only |
| `add_database.py` | Add database connection only |
| `add_sql_query.py` | Create SQL question only |
| `add_dashboard.py` | Create Sales dashboard only |
| `add_documentation.py` | Create AgentLab documentation dashboard |
| `save_auth_state.py` | Save Playwright auth state for browser agent |

Run individual scripts:

```bash
python setup_scripts/setup_login.py
python setup_scripts/add_database.py
python setup_scripts/add_sql_query.py
python setup_scripts/add_dashboard.py
python setup_scripts/add_documentation.py
python setup_scripts/save_auth_state.py
```

All scripts are **idempotent** - they skip resources that already exist.

## Docker Commands

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# Stop and remove volumes (reset everything)
docker-compose down -v

# View logs
docker-compose logs -f metabase

# Restart Metabase
docker-compose restart metabase
```

## Troubleshooting

### Metabase not starting
```bash
# Check container status
docker-compose ps

# Check logs for errors
docker-compose logs metabase
```

### Setup script fails to authenticate
- Ensure Metabase is fully initialized (check logs for "Initialization COMPLETE")
- Verify credentials in `.env` match what you expect
- If Metabase was already set up with different credentials, reset with `docker-compose down -v`

### Database not syncing
After adding the database, Metabase needs to sync metadata. This happens automatically but can take a minute. You can trigger a manual sync in Metabase UI: Admin > Databases > my-db > Sync database schema.

### Port conflicts
If port 3000 or 5433 is in use, edit `docker-compose.yml` to change the port mappings.

---

## Extra: Browser Agent (Experimental)

This project includes experimental support for a browser agent that can automate Metabase tasks using AI.

### Features

- Autonomous browser operation using Playwright
- AgentLab GenericAgent integration for action decisions
- Multi-provider LLM support via LiteLLM (Gemini, OpenAI, Azure, OpenRouter)
- Vision-enabled agents with screenshot understanding
- Structured task definitions in YAML format
- Comprehensive artifact logging (screenshots, traces, summaries)

### Additional Setup

```bash
# Install Playwright browser
playwright install chromium

# Set your LLM API key
export GEMINI_API_KEY=your-gemini-api-key
# or
export OPENAI_API_KEY=your-openai-api-key
```

### Running the Agent

```bash
# Run a sample task
metabase-agent run --task filter_and_save_question

# Run with a specific model
metabase-agent run --task filter_and_save_question --model gemini/gemini-2.0-flash

# Run in demo mode (visible browser)
metabase-agent run --task filter_and_save_question --demo

# List available tasks
metabase-agent list-tasks
```

### Supported Models

| Provider | Model Examples | API Key Variable |
|----------|---------------|------------------|
| Gemini | `gemini/gemini-2.0-flash`, `gemini/gemini-1.5-pro` | `GEMINI_API_KEY` |
| OpenAI | `gpt-4o`, `gpt-4o-mini` | `OPENAI_API_KEY` |
| Azure | `azure/your-deployment` | `AZURE_OPENAI_API_KEY` |
| OpenRouter | `openrouter/anthropic/claude-3.5-sonnet` | `OPENROUTER_API_KEY` |

### Project Structure

```
webarena-pro/
├── docker-compose.yml      # Docker environment
├── seed.sql                # Sample data
├── setup.sh                # Shell setup script
├── setup_scripts/          # Python setup scripts
│   ├── setup_all.py        # All-in-one setup
│   ├── setup_login.py      # First-time setup
│   ├── add_database.py     # Add database
│   ├── add_sql_query.py    # Create SQL question
│   ├── add_dashboard.py    # Create Sales dashboard
│   ├── add_documentation.py # Create AgentLab docs dashboard
│   └── save_auth_state.py  # Save Playwright auth state
├── .auth/                  # Auth state for browser agent (generated)
│   └── metabase_admin_state.json
├── tasks/                  # Browser agent task definitions
│   └── task_*.json
├── src/
│   └── metabase_agent/     # Browser agent (experimental)
│       ├── cli.py          # Command-line interface
│       ├── config.py       # Configuration
│       ├── runner.py       # Task orchestration
│       ├── agent/          # AgentLab adapter
│       ├── env/            # Browser environment
│       ├── tasks/          # Task definitions
│       └── evaluation/     # Success criteria
└── pyproject.toml          # Package configuration
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add feature"`
4. Push to your fork: `git push origin feature/your-feature`
5. Open a Pull Request
