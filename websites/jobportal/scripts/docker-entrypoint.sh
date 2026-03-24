#!/usr/bin/env sh
set -eu

if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  echo "Error: neither python nor python3 is available in PATH." >&2
  exit 1
fi

${PYTHON_BIN} manage.py migrate --noinput

if [ "${SEED_DATA:-1}" = "1" ]; then
  if [ "${SEED_RESET:-0}" = "1" ]; then
    ${PYTHON_BIN} manage.py seed_demo_data --reset
  else
    ${PYTHON_BIN} manage.py seed_demo_data
  fi
fi

exec "$@"
