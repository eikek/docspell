#!/usr/bin/env bash

# This script watches a directory for new files and uploads them to
# docspell. Or it uploads all files currently in the directory.
#
# It requires inotifywait, curl and sha256sum if the `-m' option is
# used.

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

CONSUMEDIR_SCRIPT=${CONSUMEDIR_SCRIPT-${0/-entrypoint/}}
CONSUMEDIR_PATH="${CONSUMEDIR_PATH-/opt/docs}"
CONSUMEDIR_POLLING_INTERVAL=${CONSUMEDIR_POLLING_INTERVAL-60}
DOCSPELL_HEADER_VALUE=${DOCSPELL_HEADER_VALUE-none}
CONSUMEDIR_ARGS=${CONSUMEDIR_ARGS-}

if [ -z "${CONSUMEDIR_ARGS}" ]; then
	CONSUMEDIR_ARGS="--path $CONSUMEDIR_PATH --iheader Docspell-Integration:$DOCSPELL_HEADER_VALUE"

	if [ "${CONSUMEDIR_INTEGRATION-n}" = "y" ]; then
		CONSUMEDIR_ARGS="$CONSUMEDIR_ARGS -i"
	fi

	if [ -z "${CONSUMEDIR_ENDPOINT-}" ]; then
		if [ "${CONSUMEDIR_INTEGRATION-n}" = "y" ]; then
			CONSUMEDIR_ENDPOINT="http://docspell-restserver:7880/api/v1/open/integration/item"
			echo "Using default CONSUMEDIR_ENDPOINT=$CONSUMEDIR_ENDPOINT"
		else
			echo "Please specify CONSUMEDIR_ENDPOINT"
			exit 1
		fi
	fi

	if [ "${CONSUMEDIR_VERBOSE-n}" = "y" ]; then
		CONSUMEDIR_ARGS="$CONSUMEDIR_ARGS -v"
	fi

	if [ "${CONSUMEDIR_UNIQUE-n}" = "y" ]; then
		CONSUMEDIR_ARGS="$CONSUMEDIR_ARGS -m"
	fi

	if [ "${CONSUMEDIR_POLLING-n}" = "y" ] || [ "${CONSUMEDIR_ONCE-n}" = "y" ]; then
		CONSUMEDIR_ARGS="$CONSUMEDIR_ARGS --once"
	fi

	CONSUMEDIR_ARGS="$CONSUMEDIR_ARGS $CONSUMEDIR_ENDPOINT"
fi

if [ "${CONSUMEDIR_POLLING-n}" = "y" ]; then
	echo "Running in polling mode"
	while [ : ]
	do
	    $CONSUMEDIR_SCRIPT $CONSUMEDIR_ARGS
	    sleep $CONSUMEDIR_POLLING_INTERVAL
	done
else
	echo "Running in inotifywait mode"
	$CONSUMEDIR_SCRIPT $CONSUMEDIR_ARGS
fi
