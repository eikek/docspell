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
CURL_OPTS=${CURL_OPTS:-}

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=omhdp:vrmi
LONGOPTS=once,distinct,help,delete,path:,verbose,recursive,dry,integration,iuser:,iheader:,poll:

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

declare -a watchdir
help=n verbose=n delete=n once=n distinct=n recursive=n dryrun=n
integration=n iuser="" iheader="" poll=""
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
        -m|--distinct)
            distinct=y
            shift
            ;;
        -r|--recursive)
            recursive=y
            shift
            ;;
        --dry)
            dryrun=y
            shift
            ;;
        -i|--integration)
            integration=y
            recursive=y
            shift
            ;;
        --iuser)
            iuser="$2"
            shift 2
            ;;
        --iheader)
            iheader="$2"
            shift 2
            ;;
        --poll)
            poll="$2"
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


showUsage() {
    echo "Upload files in a directory"
    echo ""
    echo "Usage: $0 [options] url url ..."
    echo
    echo "Options:"
    echo "  -v | --verbose        Print more to stdout. (value: $verbose)"
    echo "  -d | --delete         Delete the file if successfully uploaded. (value: $delete)"
    echo "  -p | --path <dir>     The directories to watch. This is required. (value: ${watchdir[@]})"
    echo "  -h | --help           Prints this help text. (value: $help)"
    echo "  -m | --distinct       Optional. Upload only if the file doesn't already exist. (value: $distinct)"
    echo "  -o | --once           Instead of watching, upload all files in that dir. (value: $once)"
    echo "       --poll <sec>     Run the script periodically instead of watching a directory. This can be"
    echo "                        used if watching via inotify is not possible."
    echo "  -r | --recursive      Traverse the directory(ies) recursively (value: $recursive)"
    echo "  -i | --integration    Upload to the integration endpoint. It implies -r. This puts the script in"
    echo "                          a different mode, where the first subdirectory of any given starting point"
    echo "                          is read as the collective name. The url(s) are completed with this name in"
    echo "                          order to upload files to the respective collective. So each directory"
    echo "                          given is expected to contain one subdirectory per collective and the urls"
    echo "                          are expected to identify the integration endpoint, which is"
    echo "                          /api/v1/open/integration/item/<collective-name>. (value: $integration)"
    echo "       --iheader        The header name and value to use with the integration endpoint. This must be"
    echo "                          in form 'headername:value'. Only used if '-i' is supplied."
    echo "                          (value: $iheader)"
    echo "       --iuser          The username and password for basic auth to use with the integration"
    echo "                          endpoint. This must be of form 'user:pass'. Only used if '-i' is supplied."
    echo "                          (value: $iuser)"
    echo "       --dry            Do a 'dry run', not uploading anything only printing to stdout (value: $dryrun)"
    echo ""
    echo "Arguments:"
    echo "  A list of URLs to upload the files to."
    echo ""
    echo "Example: Watch directory"
    echo "$0 --path ~/Downloads -m -dv http://localhost:7880/api/v1/open/upload/item/abcde-12345-abcde-12345"
    echo ""
    echo "Example: Upload all files in a directory"
    echo "$0 --path ~/Downloads -m -dv --once http://localhost:7880/api/v1/open/upload/item/abcde-12345-abcde-12345"
    echo ""
    echo "Example: Integration Endpoint"
    echo "$0 -i --iheader 'Docspell-Integration:test123' -m -p ~/Downloads/ http://localhost:7880/api/v1/open/integration/item"
    echo ""
}

if [ "$help" = "y" ]; then
    showUsage
    exit 0
fi

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
        >&2 echo "$1"
    fi
}

info() {
    >&2 echo $1
}

getCollective() {
    file=$(realpath "$1")
    dir=$(realpath "$2")
    collective=${file#"$dir"}
    coll=$(echo $collective | cut -d'/' -f1)
    if [ -z "$coll" ]; then
        coll=$(echo $collective | cut -d'/' -f2)
    fi
    echo $coll
}


upload() {
    dir=$(realpath "$1")
    file=$(realpath "$2")
    url="$3"
    OPTS="$CURL_OPTS"
    if [ "$integration" = "y" ]; then
        collective=$(getCollective "$file" "$dir")
        trace "- upload: collective = $collective"
        url="$url/$collective"
        if [ $iuser ]; then
            OPTS="$OPTS --user $iuser"
        fi
        if [ $iheader ]; then
            OPTS="$OPTS -H $iheader"
        fi
    fi
    if [ "$dryrun" = "y" ]; then
        info "- Not uploading (dry-run) $file to $url with opts $OPTS"
    else
        META1=""
        META2=""
        if [ "$distinct" = "y" ]; then
            META1="-F"
            META2="meta={\"multiple\": false, \"skipDuplicates\": true}"
        fi
        trace "- Uploading $file to $url with options $OPTS"
        tf1=$($MKTEMP_CMD) tf2=$($MKTEMP_CMD) rc=0
        $CURL_CMD --fail -# -o "$tf1" --stderr "$tf2" $OPTS -XPOST $META1 "$META2" -F file=@"$file" "$url"
        if [ $? -ne 0 ]; then
            info "Upload failed. Exit code: $rc"
            cat "$tf1"
            cat "$tf2"
            echo ""
            rm "$tf1" "$tf2"
            return $rc
        else
            if cat $tf1 | grep -q '{"success":false'; then
                echo "Upload failed. Message from server:"
                cat "$tf1"
                echo ""
                rm "$tf1" "$tf2"
                return 1
            else
                info "- Upload done."
                rm "$tf1" "$tf2"
                return 0
            fi
        fi
    fi
}

checksum() {
    $SHA256_CMD "$1" | cut -d' ' -f1 | xargs
}

checkFile() {
    local url="$1"
    local file="$2"
    local dir="$3"
    OPTS="$CURL_OPTS"
    if [ "$integration" = "y" ]; then
        collective=$(getCollective "$file" "$dir")
        url="$url/$collective"
        url=$(echo "$url" | sed 's,/item/,/checkfile/,g')
        if [ $iuser ]; then
            OPTS="$OPTS --user $iuser"
        fi
        if [ $iheader ]; then
            OPTS="$OPTS -H $iheader"
        fi
    else
        url=$(echo "$1" | sed 's,upload/item,checkfile,g')
    fi
    url=$url/$(checksum "$file")
    trace "- Check file via $OPTS: $url"
    tf1=$($MKTEMP_CMD) tf2=$($MKTEMP_CMD)
    $CURL_CMD --fail -v -o "$tf1" --stderr "$tf2" $OPTS -XGET -s "$url"
    if [ $? -ne 0 ]; then
        info "Checking file failed!"
        cat "$tf1" >&2
        cat "$tf2" >&2
        info ""
        rm "$tf1" "$tf2"
        echo "failed"
        return 1
    else
        if cat "$tf1" | grep -q '{"exists":true'; then
            rm "$tf1" "$tf2"
            echo "y"
        else
            rm "$tf1" "$tf2"
            echo "n"
        fi
    fi
}

process() {
    file=$(realpath "$1")
    dir="$2"
    info "---- Processing $file ----------"
    declare -i curlrc=0
    set +e
    for url in $urls; do
        if [ "$distinct" = "y" ]; then
            trace "- Checking if $file has been uploaded to $url already"
            res=$(checkFile "$url" "$file" "$dir")
            rc=$?
            curlrc=$(expr $curlrc + $rc)
            trace "- Result from checkfile: $res"
            if [ "$res" = "y" ]; then
                info "- Skipping file '$file' because it has been uploaded in the past."
                continue
            elif [ "$res" != "n" ]; then
                info "- Checking file failed, skipping the file."
                continue
            fi
        fi
        trace "- Uploading '$file' to '$url'."
        upload "$dir" "$file" "$url"
        rc=$?
        curlrc=$(expr $curlrc + $rc)
        if [ $rc -ne 0 ]; then
            trace "Upload to '$url' failed!"
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

findDir() {
    path="$1"
    for dir in "${watchdir[@]}"; do
        if [[ $path = ${dir}* ]]
        then
            echo $dir
        fi
    done
}

checkSetup() {
    for dir in "${watchdir[@]}"; do
        find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -d '' -r collective; do
            for url in $urls; do
                if [ "$integration" = "y" ]; then
                    url="$url/$(basename $collective)"
                    OPTS="$CURL_OPTS -i -s -o /dev/null -w %{http_code}"
                    if [ $iuser ]; then
                        OPTS="$OPTS --user $iuser"
                    fi
                    if [ $iheader ]; then
                        OPTS="$OPTS -H $iheader"
                    fi
                    trace "Checking integration endpoint: $CURL_CMD $OPTS "$url""
                    status=$($CURL_CMD $OPTS "$url")
                    if [ "$status" != "200" ]; then
                        echo "[WARN] Collective '$(basename $collective)' failed the setup check."
                        echo "[WARN] $status response, command: $CURL_CMD $OPTS $url"
                    fi
                fi
            done
        done
    done
}

runOnce() {
    info "Uploading all files (except hidden) in '$watchdir'."
    MD="-maxdepth 1"
    if [ "$recursive" = "y" ]; then
        MD=""
    fi
    for dir in "${watchdir[@]}"; do
        find "$dir" $MD -type f -not -name ".*" -print0 | while IFS= read -d '' -r file; do
            process "$file" "$dir"
        done
    done
}


# warn if something seems not correctly configured
checkSetup

if [ "$once" = "y" ]; then
    runOnce
else
    REC=""
    if [ "$recursive" = "y" ]; then
        REC="-r"
    fi
    if [ -z "$poll" ]; then
        $INOTIFY_CMD $REC -m --format '%w%f' -e close_write -e moved_to "${watchdir[@]}" |
            while read pathfile; do
                if [[ "$(basename "$pathfile")" != .* ]]; then
                    dir=$(findDir "$pathfile")
                    trace "The file '$pathfile' appeared below '$dir'"
                    sleep 1
                    process "$(realpath "$pathfile")" "$dir"
                else
                    trace "Skip hidden file $(realpath "$pathfile")"
                fi
            done
    else
        echo "Running in polling mode: ${poll}s"
        while [ : ]
        do
            runOnce
            sleep $poll
        done
    fi
fi
