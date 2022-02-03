#!/usr/bin/env bash

CMD="elm make --output site/static/js/bundle.js --optimize elm/Main.elm elm/Search.elm"
$CMD

inotifywait -m -e close_write -r elm/ |
    while read f; do
        $CMD
    done
