# Mattermost Seed Data

Pre-populated Mattermost Docker image with realistic mock data for agent testing.
Data is baked into the Docker image (WebArena style) — no external volumes or seed scripts needed at runtime.

## Quick Start

```bash
# Build the image (one time)
cd mattermost
docker build -t mattermost-populated .

# Run
docker run -d --name mattermost -p 8065:8065 mattermost-populated

# Reset (wipe all changes, back to clean state)
docker rm -f mattermost
docker run -d --name mattermost -p 8065:8065 mattermost-populated
```

Access Mattermost at **http://localhost:8065**

### Credentials

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `Admin@Secure123` |
| Any regular user | `john.doe`, `jane.smith`, etc. | `User@Secure123` |

## How It Works

The Docker image contains everything: Mattermost server, PostgreSQL database, and all mock data pre-loaded. This follows the same pattern as WebArena:

```bash
# WebArena shopping site
docker run --name shopping -p 7770:80 -d shopping_final_0712

# Our Mattermost
docker run --name mattermost -p 8065:8065 -d mattermost-populated
```

**Reset = `docker rm -f` + `docker run`** — each `docker run` starts from the original baked-in data. Any changes made during testing are discarded.

## What's Included

### Users (16 total)

| Username | Role | Team |
|----------|------|------|
| `admin` | System Administrator | All |
| `john.doe` | Engineering Manager | Engineering, General |
| `jane.smith` | Senior Developer | Engineering, General |
| `bob.wilson` | DevOps Engineer | Engineering, General |
| `alice.johnson` | Frontend Developer | Engineering, General |
| `charlie.brown` | Backend Developer | Engineering, General |
| `diana.prince` | QA Engineer | Engineering, General |
| `kevin.martinez` | Product Manager | Engineering, Marketing, General |
| `lisa.wang` | Security Engineer | Engineering, General |
| `mike.ross` | Junior Developer | Engineering, General |
| `natalie.kim` | Technical Writer | Engineering, General |
| `emma.davis` | Marketing Manager | Marketing, General |
| `frank.miller` | Content Writer | Marketing, General |
| `grace.lee` | UI/UX Designer | Marketing, General |
| `ivy.chen` | Data Analyst | Marketing, General |
| `henry.taylor` | HR Manager | General |

### Teams (3)

- **Engineering** — Software Engineering team (10 members)
- **Marketing** — Marketing and Growth team (5 members)
- **TechCorp General** — Company-wide hub (all 16 members)

### Channels (20 custom channels)

**Engineering (9 channels):** `project-alpha`, `project-beta`, `deployments`, `code-reviews`, `bugs-and-issues`, `standup-notes`, `tech-discussions`, `devops`, `security-alerts` (private)

**Marketing (5 channels):** `campaigns`, `social-media`, `analytics`, `content-calendar`, `design-requests`

**General (6 channels):** `announcements`, `random`, `watercooler`, `events`, `help-desk`, `new-joiners`

### Conversations

- **218 posts** with threaded replies across all channels
- **6 direct message conversations** between pairs of users
- **2 group message conversations**
- **Pinned posts** in announcements, events, and onboarding channels
- Topics: sprint planning, deployments, code reviews, bug reports, security incidents, marketing campaigns, analytics, casual chat

## Scenarios for Agent Testing

| Scenario | Example Task |
|----------|-------------|
| Information retrieval | "What is the deployment schedule for this week?" |
| Search across channels | "Find all messages about the Safari bug" |
| User lookup | "Who is the DevOps engineer?" |
| Channel management | "Create a new channel for Project Gamma" |
| Post creation | "Post the standup update in standup-notes" |
| Thread replies | "Reply to Bob's deployment notice with approval" |
| Cross-referencing | "What security issues were discussed this week?" |
| DM conversations | "Send a message to Jane about the code review" |
| Analytics queries | "What were the Q1 campaign results?" |
| Status checks | "Is there a planned deployment tonight?" |

## Adding More Mock Data

To add more data, you need to: edit `seed_data.json`, re-seed a temporary container, export the database, and rebuild the image.

### Step 1: Edit `seed_data.json`

#### Add users
```json
{
  "username": "new.user",
  "password": "User@Secure123",
  "email": "new.user@techcorp.com",
  "first_name": "New",
  "last_name": "User",
  "nickname": "newu",
  "position": "Software Engineer"
}
```
Then add the username to the `"members"` list of the relevant teams.

#### Add teams
```json
{
  "name": "data-science",
  "display_name": "Data Science",
  "description": "Data Science and ML team",
  "type": "O",
  "members": ["ivy.chen", "new.user"]
}
```

#### Add channels
Add to the `"channels"` object under the team name:
```json
"data-science": [
  {
    "name": "ml-experiments",
    "display_name": "ML Experiments",
    "purpose": "Discuss ML model experiments and results",
    "header": "Current experiment: Customer churn prediction v3",
    "type": "O"
  }
]
```

#### Add conversations
```json
"data-science": {
  "ml-experiments": [
    {
      "user": "ivy.chen",
      "message": "Started training the new churn prediction model.",
      "pin": false,
      "replies": [
        {"user": "new.user", "message": "What's the baseline accuracy?"}
      ]
    }
  ]
}
```

#### Add direct messages
```json
{
  "participants": ["ivy.chen", "new.user"],
  "messages": [
    {"user": "ivy.chen", "message": "Hey, can you review my model notebook?"},
    {"user": "new.user", "message": "Sure, send me the link!"}
  ]
}
```

### Step 2: Rebuild the image

```bash
cd mattermost

# Start a temporary container from the base image
docker run -d --name mm-temp -p 8065:8065 mattermost/mattermost-preview:latest

# Wait for it to start (~15s)
# Seed with updated data
conda activate webarena-pro
python seed_mattermost.py --url http://localhost:8065

# Export the database
docker exec mm-temp bash -c "su - postgres -c 'pg_dump -U mmuser mattermost_test'" > mattermost_seed.sql

# Clean up temp container
docker rm -f mm-temp

# Rebuild the baked image
docker build -t mattermost-populated .

# Test it
docker run -d --name mattermost -p 8065:8065 mattermost-populated
```

## File Structure

```
mattermost/
├── README.md                 # This file
├── Dockerfile                # Builds the baked Docker image
├── docker-entry-seeded.sh    # Container entrypoint (starts PostgreSQL + Mattermost)
├── mattermost_seed.sql       # PostgreSQL dump with all mock data (baked into image)
├── seed_data.json            # Mock data definitions (source of truth for re-seeding)
├── seed_mattermost.py        # Python seeder script (used during image build)
└── requirements.txt          # Python dependencies (requests)
```

## Conda Environment

```bash
# Already exists (Python 3.11 + requests)
conda activate webarena-pro

# If you need to recreate:
conda create -n webarena-pro python=3.11 -y
conda activate webarena-pro
pip install -r requirements.txt
```

## Troubleshooting

**Mattermost takes a while to start:**
- The server needs ~15-20 seconds after `docker run` to fully initialize.
- Check readiness: `curl http://localhost:8065/api/v4/system/ping`

**Docker permission issues:**
- Your user needs to be in the `docker` group.
- Quick fix: prefix commands with `sg docker -c "..."` or run `newgrp docker`.

**Port conflicts:**
- Mattermost uses port 8065. Change with: `docker run -p 9065:8065 ...`
