#!/usr/bin/env bash
set -e

# Run migrations
echo "Running migrations..."
alembic upgrade head

# Start the application
echo "Starting application..."
uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-10000}
