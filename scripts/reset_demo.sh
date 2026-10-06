#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is not set}"

URL="${DATABASE_URL/+psycopg/}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEMO_EMAIL="demo@example.com"

psql "$URL" --quiet --set ON_ERROR_STOP=1 --single-transaction \
    --command "DELETE FROM runtime_state
               WHERE scope = 'undo'
                 AND key IN (
                     SELECT p.id::text
                     FROM projects p
                     JOIN users u ON u.id = p.owner_id
                     WHERE u.email = '$DEMO_EMAIL'
                 )" \
    --command "DELETE FROM users WHERE email = '$DEMO_EMAIL'" \
    --file "$ROOT/seed.sql"

echo "Demo data restored"
