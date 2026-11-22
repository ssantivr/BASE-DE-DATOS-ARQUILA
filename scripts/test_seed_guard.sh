#!/usr/bin/env bash
# The test accounts must never reach production. No database is needed: psql is replaced.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAKE="$(mktemp -d)"
trap 'rm -rf "$FAKE"' EXIT

printf '#!/usr/bin/env bash\necho "psql was called"\n' > "$FAKE/psql"
chmod +x "$FAKE/psql"

LOCAL="postgresql://arquila:secret@localhost:5432/arquila_test"
failures=0
cases=0

run() {
    env -u RENDER -u VERCEL -u ENVIRONMENT -u PGHOSTADDR -u PGSERVICE -u PGSERVICEFILE -u PGOPTIONS \
        PATH="$FAKE:$PATH" "$@" bash "$ROOT/scripts/seed_demo_50.sh" 2>&1
}

accepts() {
    local output
    cases=$((cases + 1))

    if ! output="$(run "$@")" || ! grep -q "psql was called" <<< "$output"; then
        echo "FAIL: should accept: $*"
        failures=$((failures + 1))
    fi
}

refuses() {
    local output
    cases=$((cases + 1))

    # A crash is not a refusal: the message has to be there, and psql must not have run.
    if output="$(run "$@")" || ! grep -q "^Refused:" <<< "$output" || grep -q "psql was called" <<< "$output"; then
        echo "FAIL: should refuse: $*"
        failures=$((failures + 1))
    fi
}

accepts DATABASE_URL="$LOCAL"
accepts DATABASE_URL="postgresql+psycopg://arquila:secret@localhost:5432/arquila_test"
accepts DATABASE_URL="postgres://127.0.0.1/arquila"
accepts DATABASE_URL="postgresql://arquila@[::1]:5432/arquila"
accepts DATABASE_URL="$LOCAL" ENVIRONMENT=development

for environment in production prod staging " production" "production " $'production\r' PRODUCTION; do
    refuses DATABASE_URL="$LOCAL" ENVIRONMENT="$environment"
done

refuses DATABASE_URL="$LOCAL" RENDER=true
refuses DATABASE_URL="$LOCAL" VERCEL=1
refuses DATABASE_URL="$LOCAL" PGHOSTADDR=203.0.113.7
refuses DATABASE_URL="$LOCAL" PGSERVICE=production
refuses DATABASE_URL="$LOCAL" PGOPTIONS="-c arquila.environment=local"
refuses DATABASE_URL="$LOCAL" PGSERVICEFILE=services.conf

remote_urls=(
    "postgresql://arquila:secret@db.example.com:5432/arquila"
    "postgresql://localhost?application_name=x@db.example.com:5432/db"
    "postgresql://localhost:pa?ss@db.example.com/db"
    "postgresql://:secret?x@db.example.com/arquila"
    "postgresql://?@db.example.com/arquila"
    "postgresql://a@db.example.com,x@localhost/arquila"
    "postgresql://localhost,db.example.com/arquila"
    "postgresql://localhost/db?host=db.example.com"
    "postgresql://localhost/db?hostaddr=203.0.113.7"
    "postgresql://localhost/db?service=production"
    "postgresql://localhost/db? host=db.example.com"
    "postgresql://localhost/db?host =db.example.com"
    "postgresql://localhost/db?%68ost=db.example.com"
    "postgresql://localhost.example.com/arquila"
    "postgresql:///arquila"
    "host=db.example.com dbname=arquila"
)

for url in "${remote_urls[@]}"; do
    refuses DATABASE_URL="$url"
done

if [ "$failures" -ne 0 ]; then
    exit 1
fi

echo "Seed guard: $cases cases passed"
