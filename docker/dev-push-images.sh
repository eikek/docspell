#!/usr/bin/env bash

REPO="eikek0/"
if [ $# -eq 1 ]; then
  REPO=$1
fi

TMP_VERSION=$(cat ../version.sbt)
TMP_VERSION=${TMP_VERSION:25:99}
VERSION=${TMP_VERSION%\"}

if [[ $VERSION == *"SNAPSHOT" ]]; then
  VERSION=latest
fi

echo && echo pushing docker images for version: $VERSION && echo && echo

# disabled as this doesn't to be on Docker Hub
# echo pushing base
# docker ${REPO}docspell-base:$VERSION .


if [[ $? -eq 0 ]]; then
  echo pushing restserver
  docker push ${REPO}docspell:restserver-$VERSION
fi

if [[ $? -eq 0 ]]; then
  echo pushing joex
  docker push  ${REPO}docspell:joex-$VERSION
fi

if [[ $? -eq 0 ]]; then
  echo pushing consumedir
  docker push  ${REPO}docspell:consumedir-$VERSION
fi
