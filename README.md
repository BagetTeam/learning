# Metabase Browser Agent

A Python-based browser agent that automates tasks inside a local Metabase instance using Playwright for browser control and AgentLab's `GenericAgent` for decision-making.

## Features

- Autonomous browser operation against a local Metabase instance
- Playwright-based browser automation (headless by default)
- AgentLab GenericAgent integration for action decisions
- Multi-provider LLM support via LiteLLM (Gemini, OpenAI, Azure, OpenRouter)
- Vision-enabled agents with screenshot understanding
- Structured task definitions in YAML format
- Comprehensive artifact logging (screenshots, traces, summaries)

## Quick Start

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- LLM API key (Gemini, OpenAI, etc.)

### Installation

1. Clone the repository and install dependencies:

```bash
git clone https://github.com/YOUR-USERNAME/webarena-pro.git
cd webarena-pro
pip install -e .
playwright install chromium
```

2. Copy the environment file and configure your settings:

```bash
cp .env.example .env
```

3. Set your API key (choose one):

```bash
# For Gemini (recommended):
export GEMINI_API_KEY=your-gemini-api-key

# For OpenAI:
export OPENAI_API_KEY=your-openai-api-key

# For OpenRouter:
export OPENROUTER_API_KEY=your-openrouter-api-key
```

4. Start the local Metabase environment:

```bash
docker-compose up -d
```

5. Wait for Metabase to initialize (first run takes a few minutes), then set up a test user at http://localhost:3000.

6. Verify your setup:

```bash
metabase-agent check
```

### Running a Task

Run a sample task with Gemini (default):

```bash
metabase-agent run --task filter_and_save_question
```

Run with a specific model:

```bash
metabase-agent run --task filter_and_save_question --model gemini/gemini-2.0-flash
metabase-agent run --task filter_and_save_question --model gpt-4o
```

Run in demo mode (headed browser for debugging):

```bash
metabase-agent run --task filter_and_save_question --demo
```

List available tasks:

```bash
metabase-agent list-tasks
```

### Supported Models

The agent uses LiteLLM for multi-provider support:

| Provider | Model Examples | API Key Variable |
|----------|---------------|------------------|
| Gemini | `gemini/gemini-2.0-flash`, `gemini/gemini-1.5-pro` | `GEMINI_API_KEY` |
| OpenAI | `gpt-4o`, `gpt-4o-mini`, `gpt-4` | `OPENAI_API_KEY` |
| Azure | `azure/your-deployment` | `AZURE_OPENAI_API_KEY` |
| OpenRouter | `openrouter/anthropic/claude-3.5-sonnet` | `OPENROUTER_API_KEY` |

### Project Structure

```
metabase-agent/
  pyproject.toml          # Package configuration
  docker-compose.yml      # Local Metabase environment
  .env.example            # Environment variables template
  src/
    metabase_agent/
      cli.py              # Command-line interface
      config.py           # Configuration loading
      runner.py           # Main task orchestration
      agent/              # AgentLab adapter
      env/                # Browser environment
      tasks/              # Task definitions
      evaluation/         # Success criteria checking
      metabase/           # Metabase helpers
      logging/            # Artifact management
```

## Development

Install dev dependencies:

```bash
pip install -e ".[dev]"
```

Run tests:

```bash
pytest
```

## Contributing

Since all contributors currently have **read-only access** to the main repository, all code contributions must follow the standard **Fork and Pull Request** workflow.

1. Fork the repository to your GitHub account
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/webarena-pro.git`
3. Add upstream: `git remote add upstream https://github.com/McGill-NLP/webarena-pro.git`
4. Create a branch: `git checkout -b feature/your-feature-name`
5. Push and submit PR: `git push origin feature/your-feature-name`
6. Stay synced: `git fetch upstream && git merge upstream/main`