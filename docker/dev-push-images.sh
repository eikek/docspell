#!/usr/bin/env bash

REPO="eikek0/docspell"
if [ $# -eq 1 ]; then
  REPO=$1
fi

TMP_VERSION=$(cat ../version.sbt)
TMP_VERSION=${TMP_VERSION:25:99}
VERSION=${TMP_VERSION%\"}

if [[ $VERSION == *"SNAPSHOT" ]]; then
  VERSION=SNAPSHOT
fi

echo && echo pushing docker images for version: $VERSION && echo && echo

# disabled as this doesn't to be on Docker Hub
# echo pushing base
# docker ${REPO}-base:$VERSION .


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
