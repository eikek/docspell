#!/usr/bin/env bash

# This script watches a directory for new files and uploads them to
# docspell. Or it uploads all files currently in the directory.
#
# It requires inotifywait, curl and sha256sum if the `-m' option is
# used.

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

CURL_CMD="curl"
INOTIFY_CMD="inotifywait"
SHA256_CMD="sha256sum"
MKTEMP_CMD="mktemp"

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=om:hdp:v
LONGOPTS=once,memorize:,help,delete,path:,verbose

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

declare -a watchdir
help=n verbose=n delete=n once=n memodir=
while true; do
    case "$1" in
        -h|--help)
            help=y
            shift
            ;;
        -v|--verbose)
            verbose=y
            shift
            ;;
        -d|--delete)
            delete=y
            shift
            ;;
        -o|--once)
            once=y
            shift
            ;;
        -p|--path)
            watchdir+=("$2")
            shift 2
            ;;
        -m|--memorize)
            memodir="$2"
            shift 2
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

# handle non-option arguments
if [[ $# -eq 0 ]]; then
    echo "$0: No upload URLs given."
    exit 4
fi
urls=$@

if [ ! -d "$watchdir" ]; then
    echo "The path '$watchdir' is not a directory."
    exit 4
fi


trace() {
    if [ "$verbose" = "y" ]; then
        echo "$1"
    fi
}

info() {
    echo $1
}

upload() {
    tf=$($MKTEMP_CMD) rc=0
    $CURL_CMD -s -o "$tf" -w "%{http_code}" -XPOST -F file=@"$1" "$2" | (2>&1 1>/dev/null grep 200)
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

checksum() {
    $SHA256_CMD "$1" | cut -d' ' -f1 | xargs
}

process() {
    file="$1"
    info "---- Processing $file ----------"
    declare -i curlrc=0
    set +e
    for url in $urls; do
        if [ -n "$memodir" ] && [ -f "$memodir/.docspell-consume" ]; then
            trace "- Checking if $file has been uploaded to $url already"
            cat "$memodir/.docspell-consume" | grep "$url" | (2>&1 1>/dev/null grep "$(checksum "$file")")
            if [ $? -eq 0 ]; then
                info "- Skipping file '$file' because it has been uploaded in the past."
                continue
            fi
        fi
        trace "- Uploading '$file' to '$url'."
        upload "$file" "$url"
        rc=$?
        curlrc=$(expr $curlrc + $rc)
        if [ $rc -ne 0 ]; then
            trace "Upload to '$url' failed!"
        else
            if [ -n "$memodir" ]; then
                trace "- Adding file '$file' to list of uploaded files for '$url'"
                set +C
                echo "$(checksum "$file") : $url" >> "$memodir/.docspell-consume"
                set -C
            fi
        fi
    done
    set -e
    if [ $curlrc -ne 0 ]; then
        info "-> Some uploads failed."
    else
        trace "= File processed for all URLs"
        if [ "$delete" = "y" ]; then
            info "- Deleting file '$file'"
            set +e
            rm "$file"
            if [ $? -ne 0 ]; then
                info "- Deleting failed!"
            fi
            set -e
        fi
    fi
}

showUsage() {
    echo "Upload files in a directory"
    echo ""
    echo "Usage: $0 [options] url url ..."
    echo
    echo "Options:"
    echo "  -v | --verbose          Print more to stdout. (value: $verbose)"
    echo "  -d | --delete           Delete the file if successfully uploaded. (value: $delete)"
    echo "  -p | --path <dir>       The directories to watch. This is required. (value: ${watchdir[@]})"
    echo "  -h | --help             Prints this help text. (value: $help)"
    echo "  -m | --memorize <dir>   Optional directory (writable) to store checksums of"
    echo "                          uploaded files. This is used to skip duplicates. (value: $memodir)"
    echo "  -o | --once             Instead of watching, upload all (pdf) files in that dir. (value: $once)"
    echo ""
    echo "Arguments:"
    echo "  A list of URLs to upload the files to."
    echo ""
    echo "Example: Watch directory"
    echo "$0 --path ~/Downloads -m ~/ -dv http://localhost:7880/api/v1/open/upload/item/abcde-12345-abcde-12345"
    echo ""
    echo "Example: Upload all files in a directory"
    echo "$0 --path ~/Downloads -m ~/ -dv --once http://localhost:7880/api/v1/open/upload/item/abcde-12345-abcde-12345"
    echo ""
}


if [ "$help" = "y" ]; then
    showUsage
    exit 0
fi

if [ "$once" = "y" ]; then
    info "Uploading all files in '$watchdir'."
    for dir in "${watchdir[@]}"; do
        for file in "$dir"/*.pdf; do
            process "$file"
        done
    done
else
    $INOTIFY_CMD -m "${watchdir[@]}" -e close_write -e moved_to |
        while read path action file; do
            trace "The file '$file' appeared in directory '$path' via '$action'"
            sleep 1
            process "$path$file"
        done
fi
