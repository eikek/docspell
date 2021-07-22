#!/usr/bin/env bash
#
# This script submits a job to regenerate all preview images. This may
# be necessary if you change the dpi setting that affects the size of
# the preview.

set -e

CURL_CMD="curl"
JQ_CMD="jq"


BASE_URL="${1:-http://localhost:7880}"
TRIGGER_URL="$BASE_URL/api/v1/admin/attachments/generatePreviews"

echo "Login to trigger regenerating preview images."
echo "Using url: $BASE_URL"
echo -n "Admin Secret: "
read -s ADMIN_SECRET
echo

curl --fail -XPOST -H "Docspell-Admin-Secret: $ADMIN_SECRET" "$TRIGGER_URL"
