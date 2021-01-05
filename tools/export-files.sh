#!/usr/bin/env bash
#
# Simple script for downloading all your files. It goes through all
# items visible to the logged in user and downloads the attachments
# (the original files).
#
# The item's metadata are stored next to the files to provide more
# information about the item: tags, dates, custom fields etc. This
# contains most of your user supplied data.
#
# This script is intended for having your data outside and independent
# of docspell. Another good idea for a backup strategy is to take
# database dumps *and* storing the releases of docspell next to this
# dump.
#
# Usage:
#
# export-files.sh <docspell-base-url> <target-directory>
#
# The docspell base url is required as well as a directory to store
# all the files into.
#
# Example:
#
#    export-files.sh http://localhost:7880 /tmp/ds-download
#
# The script then asks for username and password and starts
# downloading. Files are downloaded into the following structure
# (below the given target directory):
#
# - yyyy-mm (item date)
#   - A3…XY (item id)
#     - somefile.pdf (attachments with name)
#     - metadata.json (json file with items metadata)
#
# By default, files are not overwritten, it stops if existing files
# are encountered. Configuration can be specified using environment
# variables:
#
# - OVERWRITE_FILE= if `y` then overwriting existing files is ok.
# - SKIP_FILE= if `y` then existing files are skipped (supersedes
#   OVERWRITE_FILE).
# - DROP_ITEM= if `y` the item folder is removed before attempting to
#   download it. If this is set to `y` then the above options don't
#   make sense, since they operate on the files inside the item folder
#
# Docspell sends with each file its sha256 checksum via the ETag
# header. This is used to do a integrity check after downloading.


if [ -z "$1" ]; then
    echo "The base-url to docspell is required."
    exit 1
else
    BASE_URL="$1"
    shift
fi

if [ -z "$1" ]; then
    echo "A directory is required to store the files into."
    exit 1
else
    TARGET="$1"
    shift
fi

set -o errexit -o pipefail -o noclobber -o nounset

LOGIN_URL="$BASE_URL/api/v1/open/auth/login"
SEARCH_URL="$BASE_URL/api/v1/sec/item/searchWithTags"
INSIGHT_URL="$BASE_URL/api/v1/sec/collective/insights"
DETAIL_URL="$BASE_URL/api/v1/sec/item"
ATTACH_URL="$BASE_URL/api/v1/sec/attachment"

OVERWRITE_FILE=${OVERWRITE_FILE:-n}
DROP_ITEM=${DROP_ITEM:-n}

errout() {
    >&2 echo "$@"
}

trap "{ rm -f ${TMPDIR-:/tmp}/ds-export.*; }" EXIT

mcurl() {
    tmpfile1=$(mktemp -t "ds-export.XXXXX")
    tmpfile2=$(mktemp -t "ds-export.XXXXX")
    set +e
    curl -# --fail --stderr "$tmpfile1" -o "$tmpfile2" -H "X-Docspell-Auth: $auth_token" "$@"
    status=$?
    set -e
    if [ $status -ne 0 ]; then
        errout "curl -H 'X-Docspell-Auth: …' $@"
        errout "Curl command failed (rc=$status)! Output is below."
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
if [ -z "$DS_USER" ]; then
    errout -n "Account: "
    read DS_USER
fi
if [ -z "$DS_PASS" ]; then
    errout -n "Password: "
    read -s DS_PASS
fi
echo

declare auth
declare auth_token
declare auth_time


login() {
    auth=$(curl -s --fail -XPOST \
                 --data-binary "{\"account\":\"$DS_USER\", \"password\":\"$DS_PASS\"}" "$LOGIN_URL")

    if [ "$(echo $auth | jq .success)" == "true" ]; then
        errout "Login successful"
        auth_token=$(echo $auth | jq -r .token)
        auth_time=$(date +%s)
    else
        errout "Login failed."
        exit 1
    fi
}

checkLogin() {
    elapsed=$((1000 * ($(date +%s) - $auth_time)))
    maxtime=$(echo $auth | jq .validMs)

    elapsed=$(($elapsed + 1000))
    if [ $elapsed -gt $maxtime ]; then
        errout "Need to re-login $elapsed > $maxtime"
        login
    fi
}

listItems() {
    OFFSET="${1:-0}"
    LIMIT="${2:-50}"
    errout "Get next items with offset=$OFFSET, limit=$LIMIT"
    REQ="{\"offset\":$OFFSET, \"limit\":$LIMIT, \"tagsInclude\":[],\"tagsExclude\":[],\"tagCategoriesInclude\":[], \"tagCategoriesExclude\":[],\"customValues\":[],\"inbox\":false}"

    mcurl -XPOST -H 'ContentType: application/json' -d "$REQ" "$SEARCH_URL" | jq -r '.groups[].items[]|.id'
}

fetchItemCount() {
    mcurl -XGET "$INSIGHT_URL" | jq '[.incomingCount, .outgoingCount] | add'
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

        checksum1=$(curl -s -I -H "X-Docspell-Auth: $auth_token" "$ATTACH_URL/$attachId/original" | \
                        grep -i 'etag' | cut -d' ' -f2 | jq -r)
        curl -s -o "$attachOut" -H "X-Docspell-Auth: $auth_token" "$ATTACH_URL/$attachId/original"
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
    errout "Get item $(echo $itemData | jq -r .id)"
    created=$(echo $itemData|jq '.created')
    created=$((($(echo $itemData|jq '.created') + 500) / 1000))
    itemId=$(echo $itemData | jq -r '.id')
    out="$TARGET/$(date -d @$created +%Y-%m)/$itemId"

    if [ -d "$out" ] && [ "$DROP_ITEM" == "y" ]; then
        errout "Removing item folder as requested: $out"
        rm -rf "$out"
    fi

    mkdir -p "$out"
    if [ -f "$out/metadata.json" ] && [ "$SKIP_FILE" == "y" ]; then
        errout " - Skipping file 'metadata.json' since it already exists"
    else
        if [ -f "$out/metadata.json" ] && [ "$OVERWRITE_FILE" == "y" ]; then
            errout " - Removing metadata.json as requested"
            rm -f "$out/metadata.json"
        fi
        echo $itemData | jq > "$out/metadata.json"
    fi

    while read attachId attachName; do
        attachOut="$out/$attachName"
        checkLogin
        downloadAttachment "$attachId"
    done < <(echo $itemData | jq -r '.sources[] | [.id,.name] | join(" ")')

}

login

allCount=$(fetchItemCount)
errout "Downloading $allCount items…"

allCounter=0 innerCounter=0 limit=100 offset=0 done=n

while [ "$done" = "n" ]; do
    checkLogin

    innerCounter=0
    while read id; do
        downloadItem "$id"
        innerCounter=$(($innerCounter + 1))
    done < <(listItems $offset $limit)

    allCounter=$(($allCounter + $innerCounter))
    offset=$(($offset + $limit))


    if [ $innerCounter -lt $limit ]; then
        done=y
    fi

done
errout "Downloaded $allCounter/$allCount items"
if [[ $allCounter < $allCount ]]; then
    errout
    errout "  Downloaded less items than were reported as available. This"
    errout "  may be due to items in folders that you cannot see. Or it"
    errout "  may be a bug."
    errout
fi
