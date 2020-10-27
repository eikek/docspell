#!/bin/sh

echo "Starting unoconv listener"
unoconv -l &

# replace own ocrmypdf with official dockerfile, i.e. newer version
if [ -S "/var/run/docker.sock" ]; then
  echo "Found 'docker.sock': Installing Docker and redirecting 'ocrmypdf' command to official dockerfile by jbarlow83"
  apk --no-cache add docker
  docker pull jbarlow83/ocrmypdf
  function ocrmypdf () {
    docker run jbarlow83/ocrmypdf $@
  }
  echo "Using OCRmyPDF v$(ocrmypdf --version)" && echo
fi

/opt/docspell-joex/bin/docspell-joex "$@"
