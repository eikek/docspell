#!/usr/bin/env bash

# A simple bash script that reads a configuration file to know where
# to upload a given file.
#
# The config file contains anonymous upload urls to docspell. All
# files given to this script are uploaded to those urls.
#
# The default location for the five is
# `~/.config/docspell/ds.conf'.
#
# The config file must contain lines of the form:
#
#   url.1=http://localhost:7880/api/v1/open/upload/item/<source-id>
#   url.2=...
#
# Lines starting with a `#' are ignored.

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

CURL_CMD="curl"
FILE_CMD="file"
GREP_CMD="grep"
MKTEMP_CMD="mktemp"

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=c:hsd
LONGOPTS=config:,help,skip,delete

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

delete=n skip=n help=n config="${XDG_CONFIG_HOME:-$HOME/.config}/docspell/ds.conf"
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
        -s|--skip)
            skip="y"
            shift
            ;;
        -d|--delete)
            delete="y"
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

upload() {
    tf=$($MKTEMP_CMD) rc=0
    $CURL_CMD -# -o "$tf" --stderr "$tf" -w "%{http_code}" -XPOST -F file=@"$1" "$2" | (2>&1 1>/dev/null grep 200)
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

showUsage() {
    info "Upload files to docspell"
    info ""
    info "Usage: $0 [options] file [file ...]"
    info ""
    info "Options:"
    info "  -c | --config        Provide a config file. (value: $config)"
    info "  -s | --skip          Skip non-PDF files. Otherwise an error is raised. (value: $skip)"
    info "  -d | --delete        Delete the files when successfully uploaded (value: $delete)"
    info "  -h | --help          Prints this help text. (value: $help)"
    info ""
    info "Arguments:"
    info "  One or more PDF files to upload."
    info ""
}

mimetype() {
    $FILE_CMD -b --mime-type "$1"
}

isPdf() {
    mime=$(mimetype "$1")
    [ "$mime" = "application/pdf" ]
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

if [ "$skip" = "n" ]; then
    IFS=$'\n'
    for file in $*; do
        if ! isPdf "$file"; then
            info "Not a PDF file: $file"
            exit 5
        fi
    done
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
    if isPdf "$file"; then
        for url in "${urls[@]}"; do
            info "Uploading '$file' to '$url'"
            set +e
            upload "$file" "$url"
            set -e
            if [ "$delete" = "y" ] && [ $rc -eq 0 ]; then
                info "Deleting file: $file"
                rm -f "$file"
            fi
        done
    else
        info "Skipping non-PDF file: $file"
    fi
done
