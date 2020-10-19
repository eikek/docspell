## RESTSERVER

ARG VERSION=
ARG REPO=

# hack to use args in from
FROM ${REPO}:base-binaries-${VERSION} as docspell-base-binaries


FROM ${REPO}:base-${VERSION}

RUN apk add --no-cache --virtual .restserver-dependencies openjdk11-jre bash
COPY --from=docspell-base-binaries /opt/docspell-restserver /opt/docspell-restserver
COPY restserver-entrypoint.sh /opt/restserver-entrypoint.sh

ENTRYPOINT ["/opt/restserver-entrypoint.sh"]
CMD ["/opt/docspell.conf"]
EXPOSE 7880

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:7880
