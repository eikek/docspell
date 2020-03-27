---
layout: docs
title: Quickstart
permalink: getit/
---

## {{ page.title }}

You can download pre-compiled binaries from the [Release
Page](https://github.com/eikek/docspell/releases). There are `deb`
packages and generic zip files.

You need to download the two files:

- [docspell-restserver-{{site.version}}.zip](https://github.com/eikek/docspell/releases/download/v{{site.version}}/docspell-restserver-{{site.version}}.zip)
- [docspell-joex-{{site.version}}.zip](https://github.com/eikek/docspell/releases/download/v{{site.version}}/docspell-joex-{{site.version}}.zip)


## Prerequisite

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
4. Point your browser to: <http://localhost:7880/app>
5. Register a new account, sign in and try it.

Check the [early demo video](demo) to see the basic idea. Refer to the
[documentation](doc.html) for more information on how to use docspell.
