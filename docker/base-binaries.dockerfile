FROM alpine:latest

LABEL maintainer="eikek0 <eike@docspell.org>"

ARG ELM_VERSION=0.19.1
ARG SBT_VERSION=

RUN apk add --virtual .build-dependencies --no-cache git curl bash openjdk11 npm

# ELM
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/${ELM_VERSION}/binary-for-linux-64-bit.gz
RUN gunzip elm.gz
RUN chmod +x elm
RUN mv elm /usr/local/bin/

# SBT (Scala)
ENV PATH /sbt/bin:$PATH
RUN wget https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz
RUN tar -xzvf sbt-$SBT_VERSION.tgz
RUN rm sbt-$SBT_VERSION.tgz

# DOCSPELL
RUN mkdir -p /src/docspell
COPY . /src/docspell/
# for a build without cloned project the following line would replace the one above
# RUN git -C /src clone https://github.com/eikek/docspell

WORKDIR /src/docspell
RUN sbt -J-XX:+UseG1GC -J-XX:+PrintCommandLineFlags -mem 2048 make make-zip make-tools

RUN mkdir -p /opt
RUN find "/src/docspell/modules/joex/target/universal/" -name "docspell-joex*.zip" -exec unzip {} -d "/opt/" \;
RUN mv /opt/docspell-joex-* /opt/docspell-joex
RUN find "/src/docspell/modules/restserver/target/universal/" -name "docspell-restserver*.zip" -exec unzip {} -d "/opt/" \;
RUN mv /opt/docspell-restserver-* /opt/docspell-restserver
RUN find "/src/docspell/tools/target/" -name "docspell-tools-*.zip" -exec unzip {} -d "/opt/" \;
RUN mv /opt/docspell-tools-* /opt/docspell-tools
RUN chmod 755 /opt/docspell-tools/**/*.sh

COPY ./docker/docspell.conf /opt/docspell.conf

# CLEANUP
WORKDIR /
RUN rm -r /src
RUN apk del .build-dependencies
RUN rm -r /root/.cache
