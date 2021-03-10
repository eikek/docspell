#!/usr/bin/env bash

# A simple bash script that reads a configuration file to know where
# to upload a given file.
#
# The config file contains anonymous upload urls to docspell. All
# files given to this script are uploaded to all those urls.
#
# The default location for the config file is
# `~/.config/docspell/ds.conf'.
#
# The config file must contain lines of the form:
#
#   url.1=http://localhost:7880/api/v1/open/upload/item/<source-id>
#   url.2=...
#
# Lines starting with a `#' are ignored.
#
# The `-e|--exists' option allows to skip uploading and only check
# whether a given file exists in docspell.

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

CURL_CMD="curl"
GREP_CMD="grep"
MKTEMP_CMD="mktemp"
SHA256_CMD="sha256sum"

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=c:hsde
LONGOPTS=config:,help,skip,delete,exists,allow-duplicates

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

exists=n delete=n help=n config="${XDG_CONFIG_HOME:-$HOME/.config}/docspell/ds.conf" dupes=n
while true; do
    case "$1" in
        -h|--help)
            help=y
            shift
            ;;
        -c|--config)
            config="$2"
            shift 2
            ;;
        -d|--delete)
            delete="y"
            shift
            ;;
        -e|--exists)
            exists=y
            shift
            ;;
        --allow-duplicates)
            dupes=y
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done


info() {
    echo "$1"
}

checksum() {
    $SHA256_CMD "$1" | cut -d' ' -f1 | xargs
}

checkFile() {
    local url=$(echo "$1" | sed 's,upload/item,checkfile,g')
    local file="$2"
    $CURL_CMD -XGET -s "$url/$(checksum "$file")" | (2>&1 1>/dev/null grep '"exists":true')
}

upload_file() {
    tf=$($MKTEMP_CMD) rc=0
    META1=""
    META2=""
    if [ "$dupes" = "y" ]; then
        META1="-F"
        META2="meta={\"multiple\": false, \"skipDuplicates\": false}"
    else
        META1="-F"
        META2="meta={\"multiple\": false, \"skipDuplicates\": true}"
    fi
    $CURL_CMD -# -o "$tf" --stderr "$tf" -w "%{http_code}" -XPOST $META1 "$META2" -F file=@"$1" "$2" | (2>&1 1>/dev/null grep 200)
    rc=$(expr $rc + $?)
    cat $tf | (2>&1 1>/dev/null grep '{"success":true')
    rc=$(expr $rc + $?)
    if [ $rc -ne 0 ]; then
        info "Upload failed. Exit code: $rc"
        cat "$tf"
        echo ""
        rm "$tf"
        return $rc
    else
        rm "$tf"
        return 0
    fi
}

upload() {
    if [ "$dupes" == "y" ]; then
        upload_file "$1" "$2"
    else
        checkFile "$2" "$1"
        if [ $? -eq 0 ]; then
            info "File already exists at url $2"
            return 0
        else
            upload_file "$1" "$2"
        fi
    fi
}

showUsage() {
    info "Upload files to docspell"
    info ""
    info "Usage: $0 [options] file [file ...]"
    info ""
    info "Options:"
    info "  -c | --config        Provide a config file. (value: $config)"
    info "  -d | --delete        Delete the files when successfully uploaded (value: $delete)"
    info "  -h | --help          Prints this help text. (value: $help)"
    info "  -e | --exists        Checks for the existence of a file instead of uploading (value: $exists)"
    info "  --allow-duplicates   Do not skip existing files in docspell (value: $dupes)"
    info ""
    info "Arguments:"
    info "  One or more files to check for existence or upload."
    info ""
}

if [ "$help" = "y" ]; then
    showUsage
    exit 0
fi

# handle non-option arguments
if [[ $# -eq 0 ]]; then
    echo "$0: No files given."
    exit 4
fi


## Read the config file
declare -a urls
while IFS="=" read -r k v
do
    if [[ $k == url* ]]; then
        urls+=($(echo "$v" | xargs))
    fi
done <<< $($GREP_CMD -v '^#.*' "$config")


## Main
IFS=$'\n'
for file in $*; do
    for url in "${urls[@]}"; do
        if [ "$exists" = "y" ]; then
            if checkFile "$url" "$file"; then
                info "$url $file: true"
            else
                info "$url $file: false"
            fi
        else
            info "Uploading '$file' to '$url'"
            set +e
            upload "$file" "$url"
            set -e
            if [ "$delete" = "y" ] && [ $? -eq 0 ]; then
                info "Deleting file: $file"
                rm -f "$file"
            fi
        fi
    done
done
