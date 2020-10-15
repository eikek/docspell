#!/bin/sh

export DB_STRING=jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/${DB_NAME}

/opt/docspell-restserver/bin/docspell-restserver $@
