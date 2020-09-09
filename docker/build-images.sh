#!/usr/bin/env bash

set -e

# Update the versions in joex.dockerfile and restserver.dockerfile,
# docker-compose.yml and joex/entrypoint.sh; update versions here

docker build -t eikek0/docspell:joex-0.11.1 -f joex.dockerfile  .
docker build -t eikek0/docspell:restserver-0.11.1 -f restserver.dockerfile .
docker build -t eikek0/docspell:consumedir-0.11.1 -f consumedir.dockerfile .

docker tag eikek0/docspell:restserver-0.11.1 eikek0/docspell:restserver-latest
docker tag eikek0/docspell:joex-0.11.1 eikek0/docspell:joex-latest
docker tag eikek0/docspell:consumedir-0.11.1 eikek0/docspell:consumedir-latest



# test with docker-compose up
