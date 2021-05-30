FROM alpine:latest

ARG version=
ARG restserver_url=

RUN apk add --no-cache openjdk11 bash tzdata

WORKDIR /opt
RUN wget ${restserver_url:-https://github.com/eikek/docspell/releases/download/v$version/docspell-restserver-$version.zip} && \
  unzip docspell-restserver-*.zip && \
  rm docspell-restserver-*.zip && \
  ln -snf docspell-restserver-* docspell-restserver

ENTRYPOINT ["/opt/docspell-restserver/bin/docspell-restserver"]
EXPOSE 7880

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:7880
