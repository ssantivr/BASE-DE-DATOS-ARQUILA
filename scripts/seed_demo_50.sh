#!/usr/bin/env bash
# 50 demo projects (R04), for a local database only.
# seed.sql, init.sh and reset_demo.sh never load them.
#
# The database must be marked by hand once, see docs/DEMO_DATA.md. This script never marks it.
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is not set}"

URL="${DATABASE_URL/+psycopg/}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=scripts/require_local_database.sh
source "$ROOT/scripts/require_local_database.sh"
require_local_database "$URL"

psql "$URL" --no-psqlrc --quiet --set ON_ERROR_STOP=1 --single-transaction \
    --file "$ROOT/seeds/demo_50.sql"

echo "50 demo projects loaded"
