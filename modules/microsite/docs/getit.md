---
layout: docs
title: Quickstart
permalink: getit
---

# {{ page.title }}

You can download pre-compiled binaries from the [Release
Page](https://github.com/eikek/docspell/releases). There are `deb`
packages and generic zip files. Alternatively, docspell can be
installed via [nix](doc/nix) or docker (see below).

There are the following quick ways to get docspell to run on your
machine:

- [Download, Unpack, Run](#without-docker)
- [With Docker](#with-docker)
- [NixOs Module](doc/nix#docspell-as-a-service-on-nixos)

Check the [early demo video](demo) to see the basic idea. Refer to the
[documentation](doc) for more information on how to use docspell.


## Without Docker

### Prerequisite

Install Java (use your package manager or look
[here](https://adoptopenjdk.net/)).

OCR functionality requires the following tools:

- [tesseract](https://github.com/tesseract-ocr/tesseract),
- [ghostscript](http://pages.cs.wisc.edu/~ghost/) and possibly
- [unpaper](https://github.com/Flameeyes/unpaper).

The last is not really required, but improves OCR.

PDF conversion requires the following tools:

- [unoconv](https://github.com/unoconv/unoconv)
- [wkhtmltopdf](https://wkhtmltopdf.org/)


### Using zip files

You need to download the two files:

- [docspell-restserver-{{site.version}}.zip](https://github.com/eikek/docspell/releases/download/v{{site.version}}/docspell-restserver-{{site.version}}.zip)
- [docspell-joex-{{site.version}}.zip](https://github.com/eikek/docspell/releases/download/v{{site.version}}/docspell-joex-{{site.version}}.zip)


1. Unzip both files:
   ``` bash
   $ unzip docspell-*.zip
   ```
2. Open two terminal windows and navigate to the the directory
   containing the zip files.
3. Start both components executing:
   ``` bash
   $ ./docspell-restserver*/bin/docspell-restserver
   ```
   in one terminal and
   ``` bash
   $ ./docspell-joex*/bin/docspell-joex
   ```
   in the other.
4. Point your browser to: <http://localhost:7880/app>
5. Register a new account, sign in and try it.

Note, that this setup doesn't include watching a directory. You can
use the [`consumedir.sh`](doc/tools/consumedir) tool for this or use
the docker variant below.

## With Docker

There is a [docker-compose](https://docs.docker.com/compose/) setup
available in the `/docker` folder.

1. Clone the github repository
   ```bash
   $ git clone https://github.com/eikek/docspell
   ```
2. Change into the `docker` directory:
   ```bash
   $ cd docspell/docker
   ```
3. Run `docker-compose up`:

   ```bash
   $ export DOCSPELL_HEADER_VALUE="my-secret-123"
   $ docker-compose up
   ```

   The environment variable defines a secret that is shared between
   some containers. You can define whatever you like. Please see the
   [`consumedir.sh`](doc/tools/consumedir#docker) docs for additional
   info.
4. Goto <http://localhost:7880>, signup and login. Create a folder
   `./docs/<collective-name>` and place files in there for importing
   them.

The directory contains a file `docspell.conf` that you can
[modify](doc/configure) as needed.
