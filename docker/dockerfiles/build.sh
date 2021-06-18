#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Please specify a version"
    exit 1
fi

version="$1"
if [[ $version == v* ]]; then
    version="${version:1}"
fi

push=""
if [ -z "$2" ] || [ "$2" == "--push" ]; then
    push="$2"
    if [ ! -z "$push" ]; then
        echo "Running with $push !"
    fi
else
    echo "Don't understand second argument: $2"
    exit 1
fi

if ! docker buildx version > /dev/null; then
    echo "The docker buildx command is required."
    echo "See: https://github.com/docker/buildx#binary-release"
    exit 1
fi

set -e
cd "$(dirname "$0")"

trap "{ docker buildx rm docspell-builder; }" EXIT

platforms="linux/amd64,linux/aarch64,linux/arm/v7"
docker buildx create --name docspell-builder --use

if [[ $version == *SNAPSHOT* ]]; then
    echo ">>>> Building nightly images for $version <<<<<"
    url_base="https://github.com/eikek/docspell/releases/download/nightly"

    echo "============ Building Tools ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg tools_url="$url_base/docspell-tools-$version.zip" \
           --tag docspell/tools:nightly \
           -f tools.dockerfile .

    echo "============ Building Restserver ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg restserver_url="$url_base/docspell-restserver-$version.zip" \
           --tag docspell/restserver:nightly \
           -f restserver.dockerfile .

    echo "============ Building Joex ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg joex_url="$url_base/docspell-joex-$version.zip" \
           --tag docspell/joex:nightly \
           -f joex.dockerfile .
else
    echo ">>>> Building release images for $version <<<<<"
    echo "============ Building Tools ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg version=$version \
           --tag docspell/tools:v$version \
           --tag docspell/tools:latest \
           -f tools.dockerfile .

    echo "============ Building Restserver ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg version=$version \
           --tag docspell/restserver:v$version \
           --tag docspell/restserver:latest \
           -f restserver.dockerfile .

    echo "============ Building Joex ============"
    docker buildx build \
           --platform="$platforms" $push \
           --build-arg version=$version \
           --tag docspell/joex:v$version \
           --tag docspell/joex:latest \
           -f joex.dockerfile .
fi
