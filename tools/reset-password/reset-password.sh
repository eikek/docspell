#!/usr/bin/env bash
#
# A script to reset a password.
#
# Usage:
#    ./reset-password.sh <baseurl> <admin-secret> <account>
#
# Example:
#   ./reset-password.sh http://localhost:7880 test123 your/account
#

if [ -z "$1" ]; then
    echo "The docspell base-url is required as first argument."
    exit 1
else
    BASE_URL="$1"
fi

if [ -z "$2" ]; then
    echo "The admin secret is required as second argument."
    exit 1
else
    SECRET="$2"
fi

if [ -z "$3" ]; then
    echo "The user account is required as third argument."
    exit 1
else
    USER="$3"
fi

RESET_URL="${BASE_URL}/api/v1/admin/user/resetPassword"

OUT=$(curl -s -XPOST \
           -H "Docspell-Admin-Secret: $SECRET" \
           -H "Content-Type: application/json" \
           -d "{\"account\": \"$USER\"}" \
           "$RESET_URL")


if command -v jq > /dev/null; then
    echo $OUT | jq
else
    echo $OUT
fi
