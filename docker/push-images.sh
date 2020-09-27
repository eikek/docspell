#!/usr/bin/env bash

set -e

# Update the versions in joex.dockerfile and restserver.dockerfile,
# docker-compose.yml and joex/entrypoint.sh; update versions here
docker push eikek0/docspell:joex-0.12.0
docker push eikek0/docspell:restserver-0.12.0
docker push eikek0/docspell:consumedir-0.12.0

docker push eikek0/docspell:restserver-latest
docker push eikek0/docspell:joex-latest
docker push eikek0/docspell:consumedir-latest

# test with docker-compose up
