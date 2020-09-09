#!/usr/bin/env bash

set -e

docker build -t eikek0/docspell:joex-base-1 -f joex-base.dockerfile .
docker tag eikek0/docspell:joex-base-1 eikek0/docspell:joex-base-latest
