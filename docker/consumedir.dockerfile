## CONSUMEDIR

ARG VERSION=
ARG REPO=

# hack to use args in from
FROM ${REPO}:base-${VERSION} as docspell-base


FROM alpine:latest
LABEL maintainer="eikek0 <eike@docspell.org>"

RUN apk add --no-cache curl bash inotify-tools

COPY --from=docspell-base /opt/docspell-tools /opt/docspell-tools

ENTRYPOINT /opt/docspell-tools/consumedir.sh --path /opt/docs -i --iheader Docspell-Integration:$DOCSPELL_HEADER_VALUE -m http://docspell-restserver:7880/api/v1/open/integration/item -v

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep inotifywait
