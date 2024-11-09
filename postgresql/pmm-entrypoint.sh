#!/bin/bash

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432 -U "$POSTGRES_USER"; do
  echo "Waiting for PostgreSQL to start..."
  sleep 5
done

# Create the `pg_stat_statements` extension
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

# Configure PMM Client
pmm-admin config --server-insecure-tls --server-url=https://admin:admin@pmm-server:443

# Add PostgreSQL Service to PMM
pmm-admin add postgresql \
    --username="$POSTGRES_USER" \
    --password="$POSTGRES_PASSWORD" \
    --service-name=postgresql_service \
    --query-source=pgstatements \
    --host=localhost \
    --port=5432

