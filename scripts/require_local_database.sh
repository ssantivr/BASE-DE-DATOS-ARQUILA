#!/usr/bin/env bash
# Sourced by seed_demo_50.sh. An allow-list: only a plain URL of a database on this machine.
# A tunnel also looks local, so the seed files ask the database itself for a mark as well.
# Nothing of the URL is ever printed: it carries the password.

require_local_database() {
    local url="$1"

    case "${ENVIRONMENT:-}" in
        "" | development | local | test) ;;
        *)
            echo "Refused: ENVIRONMENT is not development, local or test." >&2
            return 1
            ;;
    esac

    if [ -n "${RENDER:-}${VERCEL:-}" ]; then
        echo "Refused: demo data is never created on Render or Vercel." >&2
        return 1
    fi

    # libpq lets these replace the host that the URL names.
    if [ -n "${PGOPTIONS:-}" ]; then
        echo "Refused: PGOPTIONS is set, and it could fake the mark of the database." >&2
        return 1
    fi

    if [ -n "${PGHOSTADDR:-}${PGSERVICE:-}${PGSERVICEFILE:-}" ]; then
        echo "Refused: PGHOSTADDR, PGSERVICE or PGSERVICEFILE is set." >&2
        return 1
    fi

    local user='([A-Za-z0-9._-]+(:[A-Za-z0-9._~!*+-]*)?@)?'
    local host='(localhost|127\.0\.0\.1|\[::1\])(:[0-9]{1,5})?'
    local allowed="^postgres(ql)?://${user}${host}/[A-Za-z0-9_-]+\$"

    if [[ ! "$url" =~ $allowed ]]; then
        echo "Refused: the URL is not a plain URL of a database on this machine." >&2
        return 1
    fi
}
