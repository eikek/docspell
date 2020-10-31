#!/bin/sh

if [ ! "$1" == "--version" ]; then
  echo "Using docker image for ocrmypdf (Version: $OCRMYPDF_VERSION)"
fi
docker run --rm -v '/tmp/docspell-convert:/tmp/docspell-convert' -e "TZ=$TZ" jbarlow83/ocrmypdf:$OCRMYPDF_VERSION $@
