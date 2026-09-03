#!/bin/bash
###############################################################################
# Sincroniza el código del host con el contenedor sin tocar datos persistentes.
###############################################################################

set -euo pipefail

CONTAINER="${1:-web2-django_pastebin-1}"
PASTEBIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "No existe el contenedor: $CONTAINER" >&2
    exit 1
fi

tar \
    --exclude='./db.sqlite3' \
    --exclude='./media' \
    --exclude='./staticfiles' \
    --exclude='./*.log' \
    -C "$PASTEBIN_DIR" -cf - . |
    docker exec -i "$CONTAINER" tar -C /app -xf -

docker restart "$CONTAINER" >/dev/null
echo "Código actualizado en $CONTAINER sin sobrescribir db.sqlite3."
