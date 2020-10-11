## RESTSERVER

ARG VERSION=latest
ARG REPO=eikek0/

# hack to use args in from
FROM ${REPO}docspell:base-${VERSION} as docspell-base


FROM alpine:latest
LABEL maintainer="eikek0 <eike@docspell.org>"

RUN apk add --no-cache --virtual .restserver-dependencies openjdk11-jre bash
COPY --from=docspell-base /opt/docspell-restserver /opt/docspell-restserver

ENTRYPOINT ["/opt/docspell-restserver/bin/docspell-restserver"]
CMD ["/opt/docspell.conf"]
EXPOSE 7880

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:7880
