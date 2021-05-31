#!/usr/bin/env bash


if [ -z "$1" ]; then
    echo "Please specify a version"
    exit 1
fi

version="$1"
if [[ $version == v* ]]; then
    version="${version:1}"
fi

set -e
cd "$(dirname "$0")"

if [[ $version == *SNAPSHOT* ]]; then
    echo "============ Push Tools ============"
    docker push docspell/tools:nightly

    echo "============ Push Restserver ============"
    docker push docspell/restserver:nightly

    echo "============ Push Joex ============"
    docker push docspell/joex:nightly
else
    echo "============ Push Tools ============"
    docker push docspell/tools:v$version
    docker push docspell/tools:latest

    echo "============ Push Restserver ============"
    docker push docspell/restserver:v$version
    docker push docspell/restserver:latest

    echo "============ Push Joex ============"
    docker push docspell/joex:v$version
    docker push docspell/joex:latest
fi
