#!/usr/bin/env bash

set -e

# Update the versions in joex.dockerfile and restserver.dockerfile,
# docker-compose.yml and joex/entrypoint.sh; update versions here

docker build -t eikek0/docspell:joex-0.5.0 -f joex.dockerfile  .
docker build -t eikek0/docspell:restserver-0.5.0 -f restserver.dockerfile  .

# test with docker-compose up
