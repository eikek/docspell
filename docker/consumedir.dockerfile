## CONSUMEDIR

ARG VERSION=latest
ARG REPO=eikek0/

# hack to use args in from
FROM ${REPO}docspell:base-${VERSION} as path


FROM alpine:latest

RUN apk add --no-cache curl bash inotify-tools

COPY --from=path /opt/docspell-tools /opt/docspell-tools

ENTRYPOINT /opt/docspell-tools/consumedir.sh --path /opt/docs -i --iheader Docspell-Integration:$DOCSPELL_HEADER_VALUE -m http://docspell-restserver:7880/api/v1/open/integration/item -v

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep inotifywait
