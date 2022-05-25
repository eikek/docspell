FROM alpine:3.14

ARG version=
ARG restserver_url=
ARG TARGETPLATFORM

RUN JDKPKG="openjdk11-jre"; \
    if [[ $TARGETPLATFORM = linux/arm* ]]; then JDKPKG="openjdk8-jre"; fi; \
    apk update && \
    apk add --no-cache $JDKPKG bash tzdata && \
    apk add 'zlib=1.2.12-r1'

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
