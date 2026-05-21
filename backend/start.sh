#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Start DB if not running
if ! docker compose -f "$SCRIPT_DIR/docker-compose.yml" ps --status running | grep -q db; then
    echo "Starting PostgreSQL..."
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d
fi

echo "Waiting for PostgreSQL to be ready..."
until docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T db pg_isready -q; do
    sleep 1
done

cd "$SCRIPT_DIR"
exec uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
