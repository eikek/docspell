FROM alpine:latest

ENV UNO_URL https://raw.githubusercontent.com/unoconv/unoconv/0.9.0/unoconv

LABEL maintainer="eikek0 <eike@docspell.org>"

RUN apk add --no-cache openjdk11-jre \
    unzip \
    bash \
    curl \
    ghostscript \
    tesseract-ocr \
    tesseract-ocr-data-deu \
    unpaper \
    wkhtmltopdf \
    libreoffice \
    ttf-droid-nonlatin \
    ttf-droid \
    ttf-dejavu \
    ttf-freefont \
    ttf-liberation \
    libxml2-dev \
    libxslt-dev \
    pngquant \
    zlib-dev \
    g++ \
    qpdf \
    py3-pip \
    python3-dev \
    libffi-dev\
    qpdf-dev \
    openssl-dev \
    ocrmypdf \
  && pip3 install --upgrade pip \
  && pip3 install ocrmypdf \
  && curl -Ls $UNO_URL -o /usr/local/bin/unoconv \
  && chmod +x /usr/local/bin/unoconv \
  && mkdir -p /opt \
  && cd /opt \
  && curl -L -o docspell.zip https://github.com/eikek/docspell/releases/download/v0.11.1/docspell-joex-0.11.1.zip \
  && unzip docspell.zip \
  && rm docspell.zip \
  && apk del curl unzip libxml2-dev libxslt-dev zlib-dev g++ python3-dev py3-pip libffi-dev qpdf-dev openssl-dev


COPY entrypoint-joex.sh /opt/entrypoint.sh

EXPOSE 7878

ENTRYPOINT ["/opt/entrypoint.sh"]
