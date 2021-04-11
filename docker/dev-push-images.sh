#!/usr/bin/env bash

REPO="eikek0/docspell"
if [ $# -eq 1 ]; then
  REPO=$1
fi

VERSION=$(cat ../version.sbt | cut -d'=' -f2 | tr -d '"'|xargs)

if [[ $VERSION == *"SNAPSHOT" ]]; then
  VERSION=SNAPSHOT
else
  VERSION=v$VERSION
fi

echo && echo pushing docker images for version: $VERSION && echo && echo

# disabled as this doesn't to be on Docker Hub
# echo pushing base
# docker ${REPO}-base:$VERSION .

echo pushing restserver
docker push ${REPO}

exit 0

## still needs to be tested for a tagged version - that's why old version below is kept!

if [[ $? -eq 0 ]]; then
  echo pushing restserver
  docker push ${REPO}:restserver-$VERSION
fi

if [[ $? -eq 0 ]]; then
  echo pushing joex base
  docker push  ${REPO}:joex-base-$VERSION
fi
if [[ $? -eq 0 ]]; then
  echo pushing joex
  docker push  ${REPO}:joex-$VERSION
fi

if [[ $? -eq 0 ]]; then
  echo pushing consumedir
  docker push  ${REPO}:consumedir-$VERSION
fi
