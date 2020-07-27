#!/usr/bin/env bash

set -e

yarn install
elm make --output site/static/js/bundle.js --optimize elm/Main.elm
cd site
zola build
cd ..

echo "Site is in site/public."
