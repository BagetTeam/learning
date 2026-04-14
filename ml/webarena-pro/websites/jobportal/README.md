---
title: JobPortal
emoji: 💼
colorFrom: blue
colorTo: indigo
sdk: docker
pinned: false
---

# Job Portal

A modern job portal built with Django and Tailwind CSS, designed to connect job seekers with employers efficiently.

## Features

- User authentication for employers and job seekers
- Job posting and management
- Job search and filtering
- Application tracking
- Responsive UI for desktop and mobile

## Tech Stack

- Backend: Django
- Frontend: Tailwind CSS, Alpine.js
- Database: SQLite

## Local Development

1. Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run migrations:

```bash
python manage.py migrate
```

4. Seed reproducible demo data:

```bash
python manage.py seed_demo_data --reset
```

5. Start server:

```bash
python manage.py runserver
```

## Docker (Port 4512)

1. Build image:

```bash
docker build -t jobportal:latest .
```

2. Run app on host port 4512:

```bash
docker run --rm -p 4512:8000 jobportal:latest
```

3. Run with forced reset/reseed on startup:

```bash
docker run --rm -p 4512:8000 -e SEED_DATA=1 -e SEED_RESET=1 jobportal:latest
```

Open: http://localhost:4512

## Docker Compose (Port 4512)

Start:

```bash
docker compose up --build -d
```

Follow logs:

```bash
docker compose logs -f
```

Stop:

```bash
docker compose down
```

Force fresh seeded data on next start:

```bash
SEED_RESET=1 docker compose up --build -d
```

## Seeded Demo Data

- Command: `python manage.py seed_demo_data`
- Reset and reseed: `python manage.py seed_demo_data --reset`
- Script helper: `./scripts/seed_data.sh --reset`
- Default seeded user password: `DemoPass123!`
