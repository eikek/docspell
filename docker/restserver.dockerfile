FROM alpine:latest

LABEL maintainer="eikek0 <eike@docspell.org>"

RUN apk add --no-cache openjdk11-jre unzip curl bash

RUN mkdir -p /opt \
  && cd /opt \
  && curl -L -o docspell.zip https://github.com/eikek/docspell/releases/download/v0.6.0/docspell-restserver-0.6.0.zip \
  && unzip docspell.zip \
  && rm docspell.zip \
  && apk del unzip curl

EXPOSE 7880

ENTRYPOINT ["/opt/docspell-restserver-0.6.0/bin/docspell-restserver"]
