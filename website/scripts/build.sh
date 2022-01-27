#!/usr/bin/env bash

set -e

yarn install
npx tailwindcss -i ./styles/input.css -o ./site/public/styles.css  --config ./tailwind.config.js --postcss ./postcss.config.js
elm make --output site/static/js/bundle.js --optimize elm/Main.elm
cd site && zola build
cd ..

echo "Site is in site/public."
