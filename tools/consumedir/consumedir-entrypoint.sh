#!/usr/bin/env bash

# This script watches a directory for new files and uploads them to
# docspell. Or it uploads all files currently in the directory.
#
# It requires inotifywait, curl and sha256sum if the `-m' option is
# used.

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

showUsage() {
    echo "Options:"
    echo "  CONSUMEDIR_VERBOSE=y             Print more to stdout."
    echo "  CONSUMEDIR_DELETE=y              Delete the file if successfully uploaded. (value: $delete)"
    echo "  CONSUMEDIR_UNIQUE=y              Optional. Upload only if the file doesn't already exist. (value: $distinct)"
    echo "  CONSUMEDIR_ONCE=y        		 Instead of watching, upload all files in that dir."
    echo "  CONSUMEDIR_PATH=/opt/docs        The directories to watch."
    echo "  CONSUMEDIR_POLLING=y             Enables the polling mode instead of using inotifywait"
    echo "  CONSUMEDIR_POLLING_INTERVAL=60   Sets the interval for polling mode"
    echo "  CONSUMEDIR_ENDPOINT=             Sets the endpoint URL"
    echo "  CONSUMEDIR_INTEGRATION=y         Upload to the integration endpoint. It implies -r. This puts the script in"
    echo "                                   a different mode, where the first subdirectory of any given starting point"
    echo "                                   is read as the collective name. The url(s) are completed with this name in"
    echo "                                   order to upload files to the respective collective. So each directory"
    echo "                                   given is expected to contain one subdirectory per collective and the urls"
    echo "                                   are expected to identify the integration endpoint, which is"
    echo "                                   /api/v1/open/integration/item/<collective-name>. (value: $integration)"
    echo "  DOCSPELL_HEADER_VALUE=           The header name and value to use with the integration endpoint. This must be"
    echo "                                   in form 'headername:value'. Only used if '-i' is supplied."
    echo "  CONSUMEDIR_ARGS=                 Allows to specify a custom command line that is passed to the consumedir script"
    echo "  CONSUMEDIR_SCRIPT=               Allows to override the location of the consumedir script"
}

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
