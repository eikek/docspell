<img align="right" src="./artwork/logo-only.svg" height="150px" style="padding-left: 20px"/>

[![Build Status](https://img.shields.io/travis/eikek/docspell/master?style=flat-square)](https://travis-ci.org/eikek/docspell)
[![Scala Steward badge](https://img.shields.io/badge/Scala_Steward-helping-blue.svg?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAQCAMAAAARSr4IAAAAVFBMVEUAAACHjojlOy5NWlrKzcYRKjGFjIbp293YycuLa3pYY2LSqql4f3pCUFTgSjNodYRmcXUsPD/NTTbjRS+2jomhgnzNc223cGvZS0HaSD0XLjbaSjElhIr+AAAAAXRSTlMAQObYZgAAAHlJREFUCNdNyosOwyAIhWHAQS1Vt7a77/3fcxxdmv0xwmckutAR1nkm4ggbyEcg/wWmlGLDAA3oL50xi6fk5ffZ3E2E3QfZDCcCN2YtbEWZt+Drc6u6rlqv7Uk0LdKqqr5rk2UCRXOk0vmQKGfc94nOJyQjouF9H/wCc9gECEYfONoAAAAASUVORK5CYII=)](https://scala-steward.org)
[![License](https://img.shields.io/github/license/eikek/docspell.svg?style=flat-square&color=steelblue)](https://github.com/eikek/docspell/blob/master/LICENSE.txt)
[![Docker Pulls](https://img.shields.io/docker/pulls/eikek0/docspell?color=steelblue)](https://hub.docker.com/r/eikek0/docspell)
[![Gitter chat](https://img.shields.io/gitter/room/eikek/docspell?style=flat-square&color=steelblue)](https://gitter.im/eikek/docspell)

# Docspell

Docspell is a personal document organizer. You'll need a scanner to
convert your papers into PDF files. Docspell can then assist in
organizing the resulting mess :wink:.

You can associate tags, set correspondends, what a document is
concerned with, a name, a date and some more. If your documents are
associated with this meta data, you should be able to quickly find
them later using the search feature. But adding this manually to each
document is a tedious task. What if most of it could be done
automatically?

It is provided as a REST server and a web application and is intended
to be self-hosted.


## How it works

Documents have two main properties: a correspondent (sender or
receiver that is not you) and something the document is about. Usually
it is about a person or some thing – maybe your car, or contracts
concerning some familiy member, etc.

1. You maintain a kind of address book. It should list all possible
   correspondents and the concerning people/things. This grows
   incrementally with each *new unknown* document.
2. When docspell analyzes a document, it tries to find matches within
   your address book. It can detect the correspondent and a concerning
   person or thing. It will then associate this data to your
   documents.
3. You can inspect what docspell has done and correct it. If docspell
   has found multiple suggestions, they will be shown for you to
   select one. If it is not correctly associated, very often the
   correct one is just one click away.

The set of meta data, that docspell uses to draw suggestions from,
must be maintained manually. But usually, this data doesn't grow as
fast as the documents. After a while there is a quite complete address
book and only once in a while it has to be revisited.


## Impressions

Checkout the short demo videos (<1min), present on the [project
page](https://docspell.org/#demos). Here are some screenshots:

![screenshot-1](https://raw.githubusercontent.com/eikek/docspell/master/website/site/content/docs/webapp/docspell-curate-1.jpg)
![screenshot-2](https://raw.githubusercontent.com/eikek/docspell/master/website/site/content/docs/webapp/docspell-curate-2.jpg)


## Try it

Docspell consists of several components. The probably quickest way to
get started is to use the docker setup as described in the [get started
page](https://docspell.org/#get-started). This is only three commands
away:

``` shell
git clone https://github.com/eikek/docspell
cd docspell
DOCSPELL_HEADER_VALUE="my-secret-123" docker-compose up
```

Then go to `http://localhost:7880`, sign up and login. Use the same
name for collective and user for now. More on that can be found
[here](https://docspell.org/docs/intro/).

Other ways are documented
[here](https://docspell.org/docs/install/quickstart/):

- Install the [provided](https://github.com/eikek/docspell/releases)
  `deb` file at your debian based system.
- Download [provided](https://github.com/eikek/docspell/releases) zip
  file and run the script in `bin/`, as [described
  here](https://docspell.org/docs/install/installing/#download-unpack-run).
- Using the [nix](https://nixos.org/nix) package manager as [described
  here](https://docspell.org/docs/install/installing/#nix). A NixOS
  module is available, too.


## Documentation

The [project page](https://docspell.org) has lots of information on
how to [use and setup](https://docspell.org/docs) docspell.


## Contributions

Feedback and other contributions are very welcome! There is now a
[gitter room](https://gitter.im/eikek/docspell) for quick questions.
You can [open an issue](https://github.com/eikek/docspell/issues/new)
for questions, problems and other feedback; or make a mail to
`info [at] docspell.org`.


## License

Docspell is free software, distributed under the [GPLv3 or
later](https://spdx.org/licenses/GPL-3.0-or-later.html).
