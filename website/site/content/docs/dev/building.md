+++
title = "Building Docspell"
weight = 0
+++


You must install [sbt](https://scala-sbt.org),
[nodejs](https://www.npmjs.com/get-npm) (for the `npm` command) and
[Elm](https://elm-lang.org).

Clone the sources, `cd` into the new directory and run `sbt`. This
drops you in the sbt prompt. Then these tasks can be run:

- `make` to compile all sources (Elm + Scala)
- `make-zip` to create zip packages
- `make-deb` to create debian packages
- `make-tools` to create a zip containing the script in `tools/`
- `make-pkg` for a clean compile + building all packages (zip + deb)

The `zip` and `deb` files can be found afterwards in:

```
modules/restserver/target/universal
modules/joex/target/universal
```
