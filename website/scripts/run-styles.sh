#!/usr/bin/env bash

mkdir -p ./site/public/files
mkdir -p ./site/public/webfonts

echo "Copy webfonts…"
cp node_modules/@fontsource/*/files/* ./site/public/files/
cp node_modules/@fortawesome/fontawesome-free/webfonts/* ./site/public/webfonts/

echo "Running tailwind…"
npx tailwindcss -i ./styles/input.css -o ./site/public/styles.css  --config ./tailwind.config.js --postcss ./postcss.config.js "$1"
