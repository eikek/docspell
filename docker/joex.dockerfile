## JOEX

ARG VERSION=latest
ARG REPO=eikek0/

# hack to use args in from
FROM ${REPO}docspell:base-${VERSION} as docspell-base

# hack to use args in from
FROM ${REPO}docspell:joex-base-${VERSION} as docspell-joex-base


FROM docspell-joex-base
COPY --from=docspell-base /opt/docspell-joex /opt/docspell-joex
COPY joex-entrypoint.sh /opt/joex-entrypoint.sh

ENTRYPOINT ["/opt/joex-entrypoint.sh"]
CMD ["/opt/docspell.conf"]
EXPOSE 7878

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep -f joex/lib
