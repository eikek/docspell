## JOEX

ARG VERSION=latest
ARG REPO=eikek0/

# hack to use args in from
FROM ${REPO}docspell-base:${VERSION} as path


FROM alpine:latest
ENV JAVA_OPTS="-Xmx1536M"
ENV UNO_URL https://raw.githubusercontent.com/unoconv/unoconv/0.9.0/unoconv

RUN apk add --no-cache openjdk11-jre \
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
  && apk del curl libxml2-dev libxslt-dev zlib-dev g++ python3-dev py3-pip libffi-dev qpdf-dev openssl-dev \
  && ln -s /usr/bin/python3 /usr/bin/python

COPY --from=path /opt/docspell-joex /opt/docspell-joex
COPY joex-entrypoint.sh /opt/joex-entrypoint.sh

ENTRYPOINT ["/opt/joex-entrypoint.sh"]
CMD ["/opt/docspell.conf"]
EXPOSE 7878

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=10s \
  CMD pgrep -f joex/lib
