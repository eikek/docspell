## JOEX

ARG VERSION=
ARG REPO=

# hack to use args in from
FROM ${REPO}:base-binaries-${VERSION} as docspell-base-binaries


FROM ${REPO}:joex-base-${VERSION}

ENV OCRMYPDF_VERSION=v11.2.1

COPY --from=docspell-base-binaries /opt/docspell-joex /opt/docspell-joex
COPY joex-entrypoint.sh /opt/joex-entrypoint.sh

ENTRYPOINT ["/opt/joex-entrypoint.sh"]
CMD ["/opt/docspell.conf"]
EXPOSE 7878

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep -f joex/lib
