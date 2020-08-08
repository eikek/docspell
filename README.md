<img align="right" src="./artwork/logo-only.svg" height="150px" style="padding-left: 20px"/>

[![Build Status](https://travis-ci.org/eikek/docspell.svg?branch=master)](https://travis-ci.org/eikek/docspell)
[![Scala Steward badge](https://img.shields.io/badge/Scala_Steward-helping-blue.svg?style=flat&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAQCAMAAAARSr4IAAAAVFBMVEUAAACHjojlOy5NWlrKzcYRKjGFjIbp293YycuLa3pYY2LSqql4f3pCUFTgSjNodYRmcXUsPD/NTTbjRS+2jomhgnzNc223cGvZS0HaSD0XLjbaSjElhIr+AAAAAXRSTlMAQObYZgAAAHlJREFUCNdNyosOwyAIhWHAQS1Vt7a77/3fcxxdmv0xwmckutAR1nkm4ggbyEcg/wWmlGLDAA3oL50xi6fk5ffZ3E2E3QfZDCcCN2YtbEWZt+Drc6u6rlqv7Uk0LdKqqr5rk2UCRXOk0vmQKGfc94nOJyQjouF9H/wCc9gECEYfONoAAAAASUVORK5CYII=)](https://scala-steward.org)


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

It is provided as a REST server and a web application.

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


## Install

- Install the [provided](https://github.com/eikek/docspell/releases)
  `deb` file at your debian based system.
- Download [provided](https://github.com/eikek/docspell/releases) zip
  file and run the script in `bin/`, as [described
  here](https://docspell.org/docs/install/installing/#download-unpack-run).
- Using the [nix](https://nixos.org/nix) package manager as [described
  here](https://docspell.org/docs/install/installing/#nix). A NixOS
  module is available, too.
- Using Docker, as [described
  here](https://docspell.org/docs/install/installing/#docker).


## Documentation

The [documentation site](https://docspell.org) provides more
information.

Check the feature list and the quickstart guide to try it out:

- [Features](https://docspell.org/#feature-selection)
- [Quickstart](https://docspell.org/#get-started)


## Screenshots

Here are some (outdated) screenshots, for getting a first impression
of the web ui.

![screenshot-1](https://raw.githubusercontent.com/eikek/docspell/master/screenshots/search-view.png)
![screenshot-2](https://raw.githubusercontent.com/eikek/docspell/master/website/site/content/docs/webapp/docspell-curate-2.jpg)
![screenshot-3](https://raw.githubusercontent.com/eikek/docspell/master/website/site/content/docs/webapp/processing-queue.jpg)
