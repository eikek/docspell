FROM alpine:3.20.2

ARG version=
ARG joex_url=
ARG UNO_URL=https://raw.githubusercontent.com/unoconv/unoconv/0.9.0/unoconv
ARG TARGETPLATFORM

RUN apk update && \
    apk add --no-cache openjdk17-jre \
    tzdata \
    bash \
    curl \
    docker \
    ghostscript \
    tesseract-ocr \
    tesseract-ocr-data-deu \
    tesseract-ocr-data-fra \
    tesseract-ocr-data-ita \
    tesseract-ocr-data-spa \
    tesseract-ocr-data-por \
    tesseract-ocr-data-eng \
    tesseract-ocr-data-ces \
    tesseract-ocr-data-nld \
    tesseract-ocr-data-dan \
    tesseract-ocr-data-fin \
    tesseract-ocr-data-nor \
    tesseract-ocr-data-swe \
    tesseract-ocr-data-rus \
    tesseract-ocr-data-ron \
    tesseract-ocr-data-lav \
    tesseract-ocr-data-jpn \
    tesseract-ocr-data-heb \
    tesseract-ocr-data-lit \
    tesseract-ocr-data-pol \
    tesseract-ocr-data-est \
    tesseract-ocr-data-ukr \
    tesseract-ocr-data-slk \
    unpaper \
    weasyprint \
    libreoffice \
    ttf-droid \
    ttf-dejavu \
    ttf-freefont \
    ttf-liberation \
    font-noto-khmer \
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
  && curl -Ls $UNO_URL -o /usr/local/bin/unoconv \
  && chmod +x /usr/local/bin/unoconv \
  && apk del libxml2-dev libxslt-dev zlib-dev g++ python3-dev py3-pip libffi-dev qpdf-dev openssl-dev \
  && ln -nfs /usr/bin/python3 /usr/bin/python

# Special treatment for ocrmypdf. It is broken quite often
RUN apk add --no-cache py3-setuptools && ocrmypdf --version

WORKDIR /opt

RUN wget ${joex_url:-https://github.com/eikek/docspell/releases/download/v$version/docspell-joex-$version.zip} && \
  unzip docspell-joex-*.zip && \
  rm docspell-joex-*.zip && \
  ln -snf docspell-joex-* docspell-joex && \
  rm docspell-joex/conf/docspell-joex.conf

# temporary download traineddata directly for khmer lang
# before tesseract-ocr-data-khm being added to the registry
RUN \
  wget https://github.com/tesseract-ocr/tessdata/raw/main/khm.traineddata && \
  mv khm.traineddata /usr/share/tessdata

# Using these data files for japanese, because they work better. Includes vertical data. See #973 and #2445.
RUN \
  wget https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/master/jpn_vert.traineddata && \
  wget https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/master/jpn.traineddata && \
  mv jpn*.traineddata /usr/share/tessdata

COPY joex-entrypoint.sh /opt/joex-entrypoint.sh

ENTRYPOINT ["/opt/joex-entrypoint.sh"]
EXPOSE 7878

HEALTHCHECK --interval=1m --timeout=10s --retries=2 --start-period=30s \
  CMD wget --spider http://localhost:7878/api/info/version
