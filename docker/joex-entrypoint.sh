#!/bin/sh

export DB_STRING=jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/${DB_NAME}

echo "Starting unoconv listener"
unoconv -l &

/opt/docspell-joex/bin/docspell-joex "$@"
