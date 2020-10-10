#!/usr/bin/env bash

REPO="eikek0/"
if [ $# -eq 1 ]; then
  REPO=$1
fi

SBT_VERSION=$(grep sbt.version ../project/build.properties)
SBT_VERSION=${SBT_VERSION:12:99}

TMP_VERSION=$(cat ../version.sbt)
TMP_VERSION=${TMP_VERSION:25:99}
VERSION=${TMP_VERSION%\"}

if [[ $VERSION == *"SNAPSHOT" ]]; then
  VERSION=latest
fi

mkdir -p ./dev-log
logfile=./dev-log/build_$(date +%Y%m%d_%H%M).log
exec 1>>"$logfile" 2>&1

echo "########################################################"
date
echo && echo building docker images for version: $VERSION && echo
echo "(Repo: $REPO, SBT-Version: $SBT_VERSION)"
echo "########################################################" && echo && echo && echo

echo building base
time docker build -f ./base.dockerfile --build-arg SBT_VERSION=${SBT_VERSION} --tag ${REPO}docspell:base-$VERSION .
status=$?

if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building restserver
  time docker build -f ./restserver.dockerfile --tag ${REPO}docspell:restserver-$VERSION .
  status=$?
fi


if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building joex
  time docker build -f ./joex.dockerfile --tag ${REPO}docspell:joex-$VERSION .
  status=$?
fi

if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building consumedir
  time docker build -f ./consumedir.dockerfile --tag ${REPO}docspell:consumedir-$VERSION .
  status=$?
fi
