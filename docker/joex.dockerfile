FROM eikek0/docspell:joex-base-latest

LABEL maintainer="eikek0 <eike@docspell.org>"

RUN apk add --no-cache openjdk11-jre \
    unzip \
    bash \
    curl \
  && mkdir -p /opt \
  && cd /opt \
  && curl -L -o docspell.zip https://github.com/eikek/docspell/releases/download/v0.12.0/docspell-joex-0.12.0.zip \
  && unzip docspell.zip \
  && rm docspell.zip \
  && apk del curl unzip


COPY entrypoint-joex.sh /opt/entrypoint.sh

EXPOSE 7878

ENTRYPOINT ["/opt/entrypoint.sh"]
