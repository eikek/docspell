#!/bin/sh

echo "Starting unoconv listener"
unoconv -l &

# replace own ocrmypdf with official dockerfile, i.e. newer version
if [ -S "/var/run/docker.sock" ]; then
  echo "Found 'docker.sock': Installing Docker and redirecting 'ocrmypdf' command to official dockerfile by jbarlow83"
  apk --no-cache add docker
  docker pull -q jbarlow83/ocrmypdf:$OCRMYPDF_VERSION
  function ocrmypdf () {
    docker run jbarlow83/ocrmypdf:$OCRMYPDF_VERSION $@
  }
  echo "Using OCRmyPDF v$(ocrmypdf --version)" && echo
fi

/opt/docspell-joex/bin/docspell-joex "$@"
