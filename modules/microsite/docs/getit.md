---
layout: docs
title: Quickstart
---

## Download

You can download pre-compiled binaries from the [Release
Page](https://github.com/eikek/docspell/releases). There are `deb`
packages and a generic zip files.

You need to download the two files:

- [docspell-restserver-{{site.version}}.zip](https://github.com/eikek/docspell/releases/download/v{{site.version}}/docspell-restserver-{{site.version}}.zip)
- [docspell-joex-{{site.version}}.zip](https://github.com/eikek/docspell/releases/download/v{{site.version}}/docspell-joex-{{site.version}}.zip)


## Prerequisite

Install Java (use your package manager or look
[here](https://adoptopenjdk.net/)),
[tesseract](https://github.com/tesseract-ocr/tesseract),
[ghostscript](http://pages.cs.wisc.edu/~ghost/) and possibly
[unpaper](https://github.com/Flameeyes/unpaper). The last is not
really required, but improves OCR.


## Running

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
4. Point your browser to: <http://localhost:7880/app/index.html>
5. Register a new account, sign in and try it.

Check the [documentation](doc.html) for more information on how to use
docspell.
