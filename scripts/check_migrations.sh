#!/usr/bin/env bash
# Comprueba que las migraciones sigan el formato NNN_nombre.sql, sin números
# repetidos ni saltos, para que init.sh las aplique siempre en el mismo orden.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
expected=1
status=0

for file in "$ROOT"/migrations/*.sql; do
    name="$(basename "$file")"

    if [[ ! "$name" =~ ^([0-9]{3})_[a-z0-9_]+\.sql$ ]]; then
        echo "Nombre no válido: $name (formato esperado: 001_descripcion.sql)"
        status=1
        continue
    fi

    number=$((10#${BASH_REMATCH[1]}))

    if [ "$number" -ne "$expected" ]; then
        printf 'Numeración incorrecta: %s (se esperaba %03d)\n' "$name" "$expected"
        status=1
    fi

    if [ ! -s "$file" ]; then
        echo "Migración vacía: $name"
        status=1
    fi

    expected=$((number + 1))
done

if [ "$status" -eq 0 ]; then
    echo "Migraciones correctas: $((expected - 1))"
fi

exit "$status"
