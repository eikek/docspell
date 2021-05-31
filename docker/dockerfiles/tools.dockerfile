FROM alpine:latest

# Builds an image where all scripts in tools/ are in PATH. There are
# no assumptions what script to run, so there are no CMD or
# ENTRYPOINTS defined.
#
# The scripts are named is in tools/ only prefixed by `ds-`
#
# Run the export-files script, for example:
#
#   docker run -e DS_USER=demo -e DS_PASS=test docspell/tools:dev ds-export-files "http://localhost" .
#
# The build requires to either specify a version build argument or a
# tools_url build argument. If a tools_url argument is given, then
# this url is used to download the tools zip file. Otherwise the
# version argument is used to download from github.

LABEL maintainer="eikek0 <eike@docspell.org>"

ARG version=
ARG tools_url=

RUN apk add --no-cache curl bash inotify-tools jq sqlite

WORKDIR /opt
RUN wget ${tools_url:-https://github.com/eikek/docspell/releases/download/v$version/docspell-tools-$version.zip} && \
  unzip docspell-tools-*.zip && \
  rm docspell-tools-*.zip

RUN bash -c 'while read f; do \
    target="ds-$(basename "$f" ".sh")"; \
    echo "Installing $f -> $target"; \
    cp "$f" "/usr/local/bin/$target"; \
    chmod 755 "/usr/local/bin/$target"; \
  done < <(find /opt/docspell-tools-* -name "*.sh" -mindepth 2 -not -path "*webextension*")'
