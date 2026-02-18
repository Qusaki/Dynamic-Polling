#!/usr/bin/env bash
# Exit on error
set -o errexit

# Apply migrations
echo "Applying database migrations..."
alembic upgrade head
