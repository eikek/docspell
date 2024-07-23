FROM alpine:3.20.2

ARG version=
ARG restserver_url=
ARG TARGETPLATFORM

RUN apk update && \
    apk add --no-cache openjdk17-jre bash tzdata curl

WORKDIR /opt
RUN curl -L -O ${restserver_url:-https://github.com/eikek/docspell/releases/download/v$version/docspell-restserver-$version.zip} && \
    unzip docspell-restserver-*.zip && \
    rm docspell-restserver-*.zip && \
    ln -snf docspell-restserver-* docspell-restserver && \
    rm docspell-restserver/conf/docspell-server.conf

ENTRYPOINT ["/opt/docspell-restserver/bin/docspell-restserver"]
EXPOSE 7880

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:7880/api/info/version
