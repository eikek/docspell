#!/usr/bin/env bash
#
# This script submits a job to regenerate all preview images. This may
# be necessary if you change the dpi setting that affects the size of
# the preview.

set -e

BASE_URL="${1:-http://localhost:7880}"
LOGIN_URL="$BASE_URL/api/v1/open/auth/login"
TRIGGER_URL="$BASE_URL/api/v1/sec/collective/previews"

echo "Login to trigger regenerating preview images."
echo "Using url: $BASE_URL"
echo -n "Account: "
read USER
echo -n "Password: "
read -s PASS
echo

auth=$(curl --fail -XPOST --silent --data-binary "{\"account\":\"$USER\", \"password\":\"$PASS\"}" "$LOGIN_URL")

if [ "$(echo $auth | jq .success)" == "true" ]; then
    echo "Login successful"
    auth_token=$(echo $auth | jq -r .token)
    curl --fail -XPOST -H "X-Docspell-Auth: $auth_token" "$TRIGGER_URL"
else
    echo "Login failed."
fi
