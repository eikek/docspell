#!/bin/sh

echo "Starting unoconv listener"
unoconv -l &

# replace own ocrmypdf with official dockerfile, i.e. newer version
if [ -S "/var/run/docker.sock" ]; then
  if [ ! -f "/usr/local/bin/ocrmypdf.sh" ]; then
    echo "Found 'docker.sock': Installing Docker and redirecting 'ocrmypdf' command to official dockerfile by jbarlow83"
    apk --no-cache add docker

    mv /usr/local/bin/joex-ocrmypdf.sh /usr/local/bin/ocrmypdf
    chmod ug+x /usr/local/bin/ocrmypdf
  fi

  docker pull -q jbarlow83/ocrmypdf:$OCRMYPDF_VERSION
  echo "Using OCRmyPDF@Docker v$(ocrmypdf --version)" && echo
fi

/opt/docspell-joex/bin/docspell-joex "$@"
