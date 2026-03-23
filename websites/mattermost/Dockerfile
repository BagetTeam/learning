# Mattermost with pre-populated mock data (WebArena style)
# Data is baked into the image — no external volumes or seed scripts needed.
#
# Build:  docker build -t mattermost-populated .
# Run:    docker run -d --name mattermost -p 8065:8065 mattermost-populated
# Reset:  docker rm -f mattermost && docker run -d --name mattermost -p 8065:8065 mattermost-populated
#
# Uses Ubuntu base to avoid inherited VOLUME declarations from postgres/mattermost images.
# PostgreSQL and Mattermost binaries are copied in from their official images.
#
FROM mattermost/mattermost-preview:11.4.2 AS mm-source
FROM postgres:14 AS pg-source

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL 14 and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-14 \
    ca-certificates \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy Mattermost from the preview image
COPY --from=mm-source /mm /mm

# PostgreSQL configuration
ENV POSTGRES_USER=mmuser
ENV POSTGRES_PASSWORD=mostest
ENV POSTGRES_DB=mattermost_test
ENV PGDATA=/mm/pgdata

# Initialize PostgreSQL with our data directory (not in a VOLUME path)
RUN mkdir -p /mm/pgdata && chown postgres:postgres /mm/pgdata && \
    sudo -u postgres /usr/lib/postgresql/14/bin/initdb -D /mm/pgdata && \
    echo "host all all 0.0.0.0/0 md5" >> /mm/pgdata/pg_hba.conf && \
    echo "local all all trust" >> /mm/pgdata/pg_hba.conf

# Start PostgreSQL, create user/db, load seed data, then stop
COPY mattermost_seed.sql /tmp/mattermost_seed.sql
RUN sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D /mm/pgdata start && \
    sleep 2 && \
    sudo -u postgres psql -c "CREATE USER mmuser WITH PASSWORD 'mostest';" && \
    sudo -u postgres psql -c "CREATE DATABASE mattermost_test OWNER mmuser;" && \
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mattermost_test TO mmuser;" && \
    sudo -u postgres psql -U mmuser -d mattermost_test -f /tmp/mattermost_seed.sql > /dev/null 2>&1 && \
    sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D /mm/pgdata stop && \
    rm /tmp/mattermost_seed.sql

# Create mattermost data directory
RUN mkdir -p /mm/mattermost-data

# Copy custom entrypoint
COPY docker-entry-seeded.sh /mm/docker-entry-seeded.sh
RUN chmod +x /mm/docker-entry-seeded.sh

ENV PATH="/mm/mattermost/bin:${PATH}"
WORKDIR /mm
EXPOSE 8065

ENTRYPOINT ["/mm/docker-entry-seeded.sh"]
