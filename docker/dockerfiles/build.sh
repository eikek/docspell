#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Please specify a version"
    exit 1
fi

version="$1"
if [[ $version == v* ]]; then
    version="${version:1}"
fi

cd "$(dirname "$0")"

echo "============ Building Tools ============"
docker build \
       --build-arg version=$version \
       --tag docspell/tools:v$version \
       --tag docspell/tools:latest \
       -f tools.dockerfile .

echo "============ Building Restserver ============"
docker build \
       --build-arg version=$version \
       --tag docspell/restserver:v$version \
       --tag docspell/restserver:latest \
       -f restserver.dockerfile .

echo "============ Building Joex ============"
docker build \
       --build-arg version=$version \
       --tag docspell/joex:v$version \
       --tag docspell/joex:latest \
       -f joex.dockerfile .
