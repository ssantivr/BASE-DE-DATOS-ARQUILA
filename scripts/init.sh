#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is not set}"

URL="${DATABASE_URL/+psycopg/}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

run() {
    psql "$URL" --quiet --set ON_ERROR_STOP=1 "$@"
}

run --command "CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)"

for file in "$ROOT"/migrations/*.sql; do
    version="$(basename "$file")"
    applied="$(run --tuples-only --no-align \
        --command "SELECT 1 FROM schema_migrations WHERE version = '$version'")"

    if [ "$applied" = "1" ]; then
        continue
    fi

    run --single-transaction --file "$file" \
        --command "INSERT INTO schema_migrations (version) VALUES ('$version')"
    echo "Applied: $version"
done

if [ "${1:-}" = "--seed" ]; then
    run --single-transaction --file "$ROOT/seed.sql"
    echo "Seed data loaded"
fi
