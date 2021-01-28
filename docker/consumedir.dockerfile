## CONSUMEDIR

FROM alpine:latest
LABEL maintainer="eikek0 <eike@docspell.org>"

RUN apk add --no-cache curl bash inotify-tools

COPY ./tools/consumedir /opt/consumedir

ENTRYPOINT ["bash", "/opt/consumedir/consumedir-entrypoint.sh"]

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep bash
