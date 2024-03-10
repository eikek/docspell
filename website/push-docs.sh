#!/usr/bin/env bash

# Creates the documentation website and pushes it to the branch
# 'gh-pages' in order to be published.
#
# It is a fallback, when `sbt publish-website` is not working due to
# too large payloads (as it seems) that prohibit uploading through
# githubs http api. Therefore this script uses git (over ssh).

set -o errexit -o pipefail -o noclobber -o nounset

cdir=$(pwd)
# make sure we are in source root
if [ "$cdir" != $(git rev-parse --show-toplevel) ]; then
    echo "Please go into the source root."
    exit 1
fi

# make sure we are on branch 'current-docs'
branch=$(git branch --show-current)
if [ "$branch" != "current-docs" ]; then
    echo "Current branch is not 'current-docs', but $branch."
    exit 1
fi

# check for dirty branch
if [[ -n $(git status -s) ]]; then
    echo "Working dir is dirty. Abort."
    exit 1
fi

temp=$(mktemp -d)
trap "{ rm -rf '$temp'; }" EXIT

echo "Cloning docspell into new location $temp"
git clone git@github.com:eikek/docspell.git "$temp"
cd "$temp" && git checkout --track origin/gh-pages && rm -rf "$temp"/*

echo "Create new website from current working directory"
cd $cdir && sbt make-website

echo "Copying new site to target"
cp -R "$cdir"/website/target/zola-site/* "$temp/"

echo "Showing the diff."
cd "$temp" && git diff || true

echo "Pushing changes?"
echo "Use C-c to quit. When continuing, changes are pushed!"
read
cd "$temp" && git add . && git commit -am 'Updated gh-pages'  && git push origin gh-pages
