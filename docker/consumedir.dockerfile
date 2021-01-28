## CONSUMEDIR

ARG VERSION=
ARG REPO=

# hack to use args in from
FROM ${REPO}:base-binaries-${VERSION} as docspell-base-binaries


FROM ${REPO}:base-${VERSION}

RUN apk add --no-cache curl bash inotify-tools

COPY --from=docspell-base-binaries /opt/docspell-tools /opt/docspell-tools
COPY consumedir-entrypoint.sh  /opt/docspell-tools/consumedir/
RUN chmod 755 /opt/docspell-tools/**/*.sh

ENTRYPOINT ["bash", "/opt/docspell-tools/consumedir/consumedir-entrypoint.sh"]

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep bash
