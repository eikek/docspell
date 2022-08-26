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
elif [ "$2" == "--load" ]; then
    push="$2"
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

platforms=${PLATFORMS:-"linux/amd64,linux/arm64"}
docker buildx create --name docspell-builder --use

case $version in
    *SNAPSHOT)
        echo ">>>> Building nightly images for $version <<<<<"
        url_base="https://github.com/eikek/docspell/releases/download/nightly"

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
        ;;
    *)
        echo ">>>> Building release images for $version <<<<<"
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
esac
