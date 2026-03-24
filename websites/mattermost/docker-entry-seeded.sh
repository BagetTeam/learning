#!/bin/bash
# Custom entrypoint: starts PostgreSQL from baked-in data, then Mattermost.
# All data lives inside the image — reset = docker rm + docker run.

echo "Starting PostgreSQL"
sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D /mm/pgdata \
    -o "-c shared_buffers=256MB -c max_connections=300" \
    -l /mm/pgdata/logfile start

until pg_isready -hlocalhost -p 5432 -U mmuser &> /dev/null; do
    echo "PostgreSQL still starting..."
    sleep 2
done
echo "PostgreSQL is ready"

echo "Updating CA certificates"
update-ca-certificates --fresh >/dev/null 2>&1

echo "Starting Mattermost"
cd /mm/mattermost
exec ./bin/mattermost --config=config/config_docker.json
