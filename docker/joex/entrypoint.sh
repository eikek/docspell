#!/bin/sh

echo "Starting unoconv listener"
unoconv -l &

/opt/docspell-joex-0.5.0/bin/docspell-joex "$@"
