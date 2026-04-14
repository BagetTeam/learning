# WebArena-Pro Environments

Manage and launch WebArena-Pro website containers locally.

## Install

```bash
uv pip install .
```

## CLI

List available environments:

```bash
webarena-pro env list
```

Show help:

```bash
webarena-pro help
webarena-pro help env
webarena-pro help env list
webarena-pro env help
webarena-pro env help list
```

### CLI Helper Manual

Use these helper patterns to discover commands quickly:

```bash
# Top-level help
webarena-pro -h
webarena-pro help

# Env group help
webarena-pro env -h
webarena-pro help env
webarena-pro env help

# Specific command help
webarena-pro env list -h
webarena-pro help env list
webarena-pro env help list
```

Start an environment container:

```bash
webarena-pro env start flight-search
```

Start all environment containers (waits 60 seconds before reporting readiness):

```bash
webarena-pro env start all
```

Restart all environment containers (stop/remove and start again):

```bash
webarena-pro env restart all
```

Stop all environment containers (remove if they exist):

```bash
webarena-pro env stop all
```

Run the dashboard server and open the web index page:

```bash
webarena-pro serve --host 127.0.0.1 --port 8080
```

Then open: `http://127.0.0.1:8080`

The dashboard can start/restart/stop each environment and provides a **Connect** link when a container URL is available.

## Fixed App Ports

Application host ports are hardcoded and fixed in the codebase:

- `nextcloud` -> `3210`
- `flight-search` -> `2210`
- `notion` -> `3211`

The CLI and dashboard do not support runtime port overrides.
