#!/usr/bin/env bash
#
# Uses the `screenshot.sh` script to create one screenshot per theme.
#
# First sets light theme and takes a screenshot, then sets dark theme
# and calls screenshot.sh again
#
# Might need to fiddle with the xdotool command


docspell_url=http://localhost:7880
docspell_user=demo
docspell_pass=test

screenshot="$(dirname $0)/screenshot.sh"

out_base="$1"

work_dir=$(mktemp -dt screenshot2-script.XXXXXX)
export HOME=$work_dir
export RATIO="16:9"
export WAIT_SEC=${WAIT_SEC:-4}
#export TOP_CUT=400

dsc write-default-config
sed -i "s,http://localhost:7880,$docspell_url,g" $HOME/.config/dsc/config.toml

set_theme() {
    dsc login -u $docspell_user --password $docspell_pass 2>&1 > /dev/null
    local token=$(cat $HOME/.config/dsc/dsc-token.json | jq -r '.token')
    data=$(curl -sSL -H "X-Docspell-Auth: $token" $docspell_url/api/v1/sec/clientSettings/webClient | jq ".uiTheme=\"$1\"")

    curl -sSL -H "X-Docspell-Auth: $token" -XPUT --data "$data" $docspell_url/api/v1/sec/clientSettings/user/webClient
    xdotool search --name "Mozilla Firefox" | xargs xdotool windowactivate && xdotool key F5
}

set_theme "Light"
$screenshot "${out_base}.png"
set_theme "dark"
$screenshot "${out_base}_dark.png"
