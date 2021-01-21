# Contributing

Thank you very much for your interest in this project!

Contributions are possible by various means.


## Feedback

Feedback is very important and most welcome! You can currently use the
[issue tracker](https://github.com/eikek/docspell/issues/new) or the
[gitter room](https://gitter.im/eikek/docspell) to leave feedback or
say hi. You can also access the gitter room using your favorite
[matrix](https://matrix.org/) client.

If you don't like to sign up to github/matrix or like to reach me
personally, you can make a mail to `info [at] docspell.org` or on
matrix, via `@eikek:matrix.org`.

If you find a feature request already filed, you can vote on it. I
tend to prefer most voted requests to those without much attention.


## Documentation

The website `https://docspell.org` contains the main documentation and
is also hosted in this repository. The sources are in `/website`
folder. It is built using [zola](https://github.com/getzola/zola), a
static site generator.

If you want to contribute to the documentation, please see the
[README](https://github.com/eikek/docspell/blob/master/website/README.md)
in this folder for how to get started. It is recommended to install
[nix](https://nixos.org/guides/install-nix.html) in order to not
fiddle with dependencies.

The main content is in `/website/site/content` and sibling directories.

There are always two versions of the website: the currently released
version and the development version (which is becoming the next
release). If you want to contribute to the current docs, please base
your PR off the `current-docs` branch.


## Code

Code is very welcome, too, of course.

If you want to work on something larger, please create an issue or
let's discuss it on gitter first.

The backend of docspell is written in [Scala](https://scala-lang.org)
using a pure functional style. It builds on great libraries from the
[typelevel](https://typelevel.org) ecosystem, i.e.
[cats](https://typelevel.org/cats), [fs2](https://fs2.io),
[doobie](https://tpolecat.github.io/doobie/) and
[http4s](https://http4s.org/). The backend consists of two components:
a http/rest server and the job executor, both running in separate
processes.

The web frontend is written in [Elm](https://elm-lang.org), which is a
nice functional language that compiles to javascript. The frontend is
included in the http/restserver component. The CSS is provided by
[Fomantic-UI](https://fomantic-ui.com/), where a [custom
build](https://github.com/eikek/fomantic-slim-default) of it is used
to avoid dependency to a google font and jquery (all javascript
modules are removed).

The [development](https://docspell.org/docs/dev/building/) page
contains some tips to get started.
