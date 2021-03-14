#!/usr/bin/env bash
#
# Script for downloading files (the PDF versions) flat in the current
# directory. It takes a search query for selecting what to download.
# Metadata is not downloaded, only the files.
#
# Usage:
#
# download-files.sh <docspell-base-url> <query>
#
# The docspell base url is required as well as a search query. The
# output directory is the current directory, and can be defined via
# env variable "TARGET_DIR".
#
# Example:
#
#    download-files.sh http://localhost:7880 "tag:todo folder:work"
#
# The script then asks for username and password and starts
# downloading. For more details about the query, please see the docs
# here: https://docspell.org/docs/query/

CURL_CMD="curl"
JQ_CMD="jq"


if [ -z "$1" ]; then
    echo "The base-url to docspell is required."
    exit 1
else
    BASE_URL="$1"
    shift
fi

if [ -z "$1" ]; then
    errout "A search query is required"
    exit 1
else
    QUERY="$1"
    shift
fi

set -o errexit -o pipefail -o noclobber -o nounset

LOGIN_URL="$BASE_URL/api/v1/open/auth/login"
SEARCH_URL="$BASE_URL/api/v1/sec/item/search"
DETAIL_URL="$BASE_URL/api/v1/sec/item"
ATTACH_URL="$BASE_URL/api/v1/sec/attachment"

OVERWRITE_FILE=${OVERWRITE_FILE:-n}
TARGET=${TARGET_DIR:-"$(pwd)"}

errout() {
    >&2 echo "$@"
}

trap "{ rm -f ${TMPDIR-:/tmp}/ds-download.*; }" EXIT

mcurl() {
    tmpfile1=$(mktemp -t "ds-download.XXXXX")
    tmpfile2=$(mktemp -t "ds-download.XXXXX")
    set +e
    "$CURL_CMD" -# --fail --stderr "$tmpfile1" -o "$tmpfile2" -H "X-Docspell-Auth: $auth_token" "$@"
    status=$?
    set -e
    if [ $status -ne 0 ]; then
        errout "$CURL_CMD -H 'X-Docspell-Auth: …' $@"
        errout "curl command failed (rc=$status)! Output is below."
        cat "$tmpfile1" >&2
        cat "$tmpfile2" >&2
        rm -f "$tmpfile1" "$tmpfile2"
        return 2
    else
        ret=$(cat "$tmpfile2")
        rm "$tmpfile2" "$tmpfile1"
        echo $ret
    fi
}


errout "Login to Docspell."
errout "Using url: $BASE_URL"
if [ -z "${DS_USER:-}" ]; then
    errout -n "Account: "
    read DS_USER
fi
if [ -z "${DS_PASS:-}" ]; then
    errout -n "Password: "
    read -s DS_PASS
fi
echo

declare auth
declare auth_token
declare auth_time


login() {
    auth=$("$CURL_CMD" -s --fail -XPOST \
                 --data-binary "{\"account\":\"$DS_USER\", \"password\":\"$DS_PASS\"}" "$LOGIN_URL")

    if [ "$(echo $auth | "$JQ_CMD" .success)" == "true" ]; then
        errout "Login successful"
        auth_token=$(echo $auth | "$JQ_CMD" -r .token)
        auth_time=$(date +%s)
    else
        errout "Login failed."
        exit 1
    fi
}

checkLogin() {
    elapsed=$((1000 * ($(date +%s) - $auth_time)))
    maxtime=$(echo $auth | "$JQ_CMD" .validMs)

    elapsed=$(($elapsed + 1000))
    if [ $elapsed -gt $maxtime ]; then
        errout "Need to re-login $elapsed > $maxtime"
        login
    fi
}

listItems() {
    OFFSET="${1:-0}"
    LIMIT="${2:-50}"
    QUERY="$3"
    errout "Get next items with offset=$OFFSET, limit=$LIMIT"
    REQ="{\"offset\":$OFFSET, \"limit\":$LIMIT, \"query\":\" $QUERY \"}"

    mcurl -XPOST -H 'ContentType: application/json' -d "$REQ" "$SEARCH_URL" | "$JQ_CMD" -r '.groups[].items[]|.id'
}


fetchItem() {
    mcurl -XGET "$DETAIL_URL/$1"
}

downloadAttachment() {
    attachId="$1"
    errout " - Download '$attachName' ($attachId)"

    if [ -f "$attachOut" ] && [ "$SKIP_FILE" == "y" ]; then
        errout " - Skipping file '$attachOut' since it already exists"
    else
        if [ -f "$attachOut" ] && [ "$OVERWRITE_FILE" == "y" ]; then
            errout " - Removing attachment file as requested: $attachOut"
            rm -f "$attachOut"
        fi

        DL_URL="$ATTACH_URL/$attachId"

        checksum1=$("$CURL_CMD" -s -I -H "X-Docspell-Auth: $auth_token" "$DL_URL" | \
                        grep -i 'etag' | cut -d' ' -f2 | "$JQ_CMD" -r)
        "$CURL_CMD" -s -o "$attachOut" -H "X-Docspell-Auth: $auth_token" "$DL_URL"
        checksum2=$(sha256sum "$attachOut" | cut -d' ' -f1 | xargs)
        if [ "$checksum1" == "$checksum2" ]; then
            errout " - Checksum ok."
        else
            errout " - WARNING: Checksum mismatch! Server: $checksum1 Downloaded: $checksum2"
            return 3
        fi
    fi
}

downloadItem() {
    checkLogin
    itemData=$(fetchItem "$1")
    errout "Get item $(echo $itemData | "$JQ_CMD" -r .id)"
    created=$(echo $itemData|"$JQ_CMD" '.created')
    created=$((($(echo $itemData|"$JQ_CMD" '.created') + 500) / 1000))
    itemId=$(echo $itemData | "$JQ_CMD" -r '.id')
    #    out="$TARGET/$(date -d @$created +%Y-%m)/$itemId"
    out="$TARGET"

    if [ -d "$out" ] && [ "${DROP_ITEM:-}" == "y" ]; then
        errout "Removing item folder as requested: $out"
        rm -rf "$out"
    fi

    mkdir -p "$out"

    while read attachId attachName; do
        attachOut="$out/$attachName"
        checkLogin
        downloadAttachment "$attachId"
    done < <(echo $itemData | "$JQ_CMD" -r '.attachments[] | [.id,.name] | join(" ")')
}

login

errout "Downloading files…"

allCounter=0 innerCounter=0 limit=100 offset=0 done=n

while [ "$done" = "n" ]; do
    checkLogin

    innerCounter=0
    while read id; do
        downloadItem "$id"
        innerCounter=$(($innerCounter + 1))
    done < <(listItems $offset $limit "$QUERY")

    allCounter=$(($allCounter + $innerCounter))
    offset=$(($offset + $limit))


    if [ $innerCounter -lt $limit ]; then
        done=y
    fi

done
errout "Downloaded $allCounter items"
