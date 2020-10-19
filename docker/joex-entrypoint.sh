#!/bin/sh

echo "Starting unoconv listener"
unoconv -l &

/opt/docspell-joex/bin/docspell-joex "$@"
