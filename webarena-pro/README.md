# WebArena-Pro

WebArena-Pro is a task benchmark package for running browser agents on locally hosted web environments (for example `nextcloud`, `flight-search`, and `jobportal`) using AgentLab + BrowserGym.

This package provides:
- A benchmark loader that builds tasks from a JSON task set
- Task/environment wrappers for WebArena-Pro websites
- A study runner to launch evaluations with AgentLab agents

## Repository context

This directory (`webarena-pro/`) is one package inside a larger workspace.

- `webarena-pro-envs/` manages website containers and local URLs
- `AgentLab/` provides experiment and agent infrastructure
- `webarena-pro/` contains benchmark/task/study code for WebArena-Pro

## Requirements

- Python `>=3.12`
- Docker (for website environments)
- A working local checkout of this monorepo
- API keys for the model/provider you run (for example OpenAI)

## Install

From the monorepo root:

```bash
cd webarena-pro
uv pip install -e .
```

## Start the local web environments

The benchmark expects local websites to be available at fixed ports (configured in `webarena_pro/benchmark/defaults.py`).

From the monorepo root:

```bash
cd webarena-pro-envs
uv pip install .
webarena-pro env start all
```

Useful environment commands:

```bash
webarena-pro env list
webarena-pro env restart all
webarena-pro env stop all
```

## Run a benchmark study

An example script is included at `scripts/run_gpt_5_nano.py`.

From `webarena-pro/`:

```bash
uv run scripts/run_gpt_5_nano.py
```

This creates a `WebArenaProBenchmark`, wraps it in `WebArenaProStudy`, and runs with Ray backend.

## Programmatic usage

```python
from agentlab.agents.generic_agent import GenericAgentArgs
from agentlab.llm.llm_configs import CHAT_MODEL_ARGS_DICT
from agentlab.agents.generic_agent.agent_configs import FLAGS_GPT_4o

from webarena_pro.benchmark.benchmark import WebArenaProBenchmark
from webarena_pro.study import WebArenaProStudy

agent = GenericAgentArgs(
	chat_model_args=CHAT_MODEL_ARGS_DICT["openai/gpt-5-nano-2025-08-07"],
	flags=FLAGS_GPT_4o,
)

benchmark = WebArenaProBenchmark()
study = WebArenaProStudy(agent_args=[agent], benchmark=benchmark, comment="local run")
study.run(n_jobs=1, parallel_backend="ray", n_relaunch=1)
```

## Analyzing traces with xray

Analyze traces using `agentlab-xray`:

```bash
source .venv/bin/activate
agentlab-xray
```

## Task set and URLs

- Default task file: `src/webarena_pro/config/test.raw.json`
- URLs and credentials: `src/webarena_pro/benchmark/defaults.py`

Current default URLs:
- `nextcloud` → `http://localhost:3210`
- `flight-search` → `http://localhost:2210`
- `jobportal` → `http://localhost:4510`

## Run tests

From `webarena-pro/`:

```bash
uv run pytest -q
```

Focused benchmark/task tests:

```bash
uv run pytest tests/test_task.py tests/test_benchmark.py -q
```

## Project layout

```text
webarena-pro/
├── scripts/
│   └── run_gpt_5_nano.py
├── src/webarena_pro/
│   ├── benchmark/
│   │   ├── benchmark.py
│   │   ├── env.py
│   │   ├── task.py
│   │   └── defaults.py
│   ├── config/
│   │   └── test.raw.json
│   ├── eval/
│   └── study.py
└── tests/
```

## Notes

- Ensure `webarena-pro-envs` services are up before running studies.
- Some tasks may require login flows using credentials in defaults.
- For reproducible runs, keep local environments and model settings fixed across runs.
