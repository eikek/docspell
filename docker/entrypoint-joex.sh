#!/bin/sh

echo "Starting unoconv listener"
unoconv -l &

/opt/docspell-joex-0.11.0/bin/docspell-joex "$@"
