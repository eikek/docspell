FROM alpine:latest

ARG version=
ARG restserver_url=
ARG TARGETPLATFORM

RUN JDKPKG="openjdk11"; \
    if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then JDKPKG="openjdk8"; fi; \
    apk add --no-cache $JDKPKG bash tzdata

WORKDIR /opt
RUN wget ${restserver_url:-https://github.com/eikek/docspell/releases/download/v$version/docspell-restserver-$version.zip} && \
  unzip docspell-restserver-*.zip && \
  rm docspell-restserver-*.zip && \
  ln -snf docspell-restserver-* docspell-restserver && \
  rm docspell-restserver/conf/docspell-server.conf

ENTRYPOINT ["/opt/docspell-restserver/bin/docspell-restserver", "-J-XX:+UseG1GC"]
EXPOSE 7880

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:7880/api/info/version
