#!/usr/bin/env bash
# Checks that the migrations are named NNN_name.sql, with no repeated or skipped
# numbers, so that init.sh always applies them in the same order.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
expected=1
status=0

for file in "$ROOT"/migrations/*.sql; do
    name="$(basename "$file")"

    if [[ ! "$name" =~ ^([0-9]{3})_[a-z0-9_]+\.sql$ ]]; then
        echo "Invalid name: $name (expected format: 001_description.sql)"
        status=1
        continue
    fi

    number=$((10#${BASH_REMATCH[1]}))

    if [ "$number" -ne "$expected" ]; then
        printf 'Wrong number: %s (expected %03d)\n' "$name" "$expected"
        status=1
    fi

    if [ ! -s "$file" ]; then
        echo "Empty migration: $name"
        status=1
    fi

    expected=$((number + 1))
done

if [ "$status" -eq 0 ]; then
    echo "Valid migrations: $((expected - 1))"
fi

exit "$status"
