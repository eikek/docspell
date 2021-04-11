#!/usr/bin/env bash

REPO="eikek0/docspell"
if [ $# -eq 1 ]; then
  REPO=$1
fi

SBT_VERSION=$(grep sbt.version ../project/build.properties|cut -d'=' -f2|xargs)
VERSION=$(cat ../version.sbt | cut -d'=' -f2 | tr -d '"'|xargs)

if [[ $VERSION == *"SNAPSHOT" ]]; then
  VERSION=SNAPSHOT
else
  VERSION=v$VERSION
fi

# if automated build by docker, don't spool log to file
if [[ $LOG_TO_FILE -eq 1 ]]; then
  logfile=./dev-log/build_$(date +%Y%m%d_%H%M).log
  echo logging to logfile: $logfile
  echo In order to log to console set 'LOG_TO_CONSOLE' to 1
  mkdir -p ./dev-log
  exec 1>>"$logfile" 2>&1
else
  echo "logging to console..." && echo
fi

echo "########################################################"
date
echo && echo building docker images for version: $VERSION && echo
echo "(Repo: $REPO, SBT-Version: $SBT_VERSION)"
echo "########################################################" && echo && echo && echo

echo building base-binaries
time docker build -f ./base-binaries.dockerfile --build-arg SBT_VERSION=${SBT_VERSION} --tag ${REPO}:base-binaries-$VERSION ..
status=$?

if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building base
  time docker build -f ./base.dockerfile --tag ${REPO}:base-$VERSION .
  status=$?
fi

if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building restserver
  time docker build -f ./restserver.dockerfile --tag ${REPO}:restserver-$VERSION --build-arg REPO=$REPO --build-arg VERSION=$VERSION .
  status=$?

  if [[ $status -eq 0 ]] && [[ "$VERSION" != "SNAPSHOT" ]]; then
     docker tag ${REPO}:restserver-$VERSION ${REPO}:restserver-LATEST
  fi
fi

if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building joex base
  time docker build -f ./joex-base.dockerfile --tag ${REPO}:joex-base-$VERSION --build-arg REPO=$REPO --build-arg VERSION=$VERSION .
  status=$?
fi
if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building joex
  time docker build -f ./joex.dockerfile --tag ${REPO}:joex-$VERSION --build-arg REPO=$REPO --build-arg VERSION=$VERSION .
  status=$?

  if [[ $status -eq 0 ]] && [[ "$VERSION" != "SNAPSHOT" ]]; then
     docker tag ${REPO}:joex-$VERSION ${REPO}:joex-LATEST
  fi
fi

if [[ $status -eq 0 ]]; then
  echo && echo && echo && echo && echo "########################################################"
  echo building consumedir
  time docker build -f ./consumedir.dockerfile --tag ${REPO}:consumedir-$VERSION --build-arg REPO=$REPO --build-arg VERSION=$VERSION .
  status=$?

  if [[ $status -eq 0 ]] && [[ "$VERSION" != "SNAPSHOT" ]]; then
     docker tag ${REPO}:consumedir-$VERSION ${REPO}:consumedir-LATEST
  fi
fi

echo && echo && echo
echo "######################## done ########################"
date
