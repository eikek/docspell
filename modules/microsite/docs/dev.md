---
layout: docs
title: Development
---


# {{page.title}}


## Building

[Sbt](https://scala-sbt.org) is used to build the application. Clone
the sources and run:

- `make` to compile all sources (Elm + Scala)
- `make-zip` to create zip packages
- `make-deb` to create debian packages
- `make-pkg` for a clean compile + building all packages (zip + deb)

The zip files can be found afterwards in:

```
modules/restserver/target/universal
modules/joex/target/universal
```


## Starting Servers with `reStart`

When developing, it's very convenient to use the [revolver sbt
plugin](https://github.com/spray/sbt-revolver). Start the sbt console
and then run:

```
sbt:docspell-root> restserver/reStart
```

This starts a REST server. Once this started up, type:

```
sbt:docspell-root> joex/reStart
```

if also a joex component is required. Prefixing the commads with `~`,
results in recompile+restart once a source file is modified.


## Custom config file

The sbt build is setup such that a file `dev.conf` in the directory
`local` (at root of the source tree) is picked up as config file, if
it exists. So you can create a custom config file for development. For
example, a custom database for development may be setup this way:

```
#jdbcurl = "jdbc:h2:///home/dev/workspace/projects/docspell/local/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"
jdbcurl = "jdbc:postgresql://localhost:5432/docspelldev"
#jdbcurl = "jdbc:mariadb://localhost:3306/docspelldev"

docspell.server {
  backend {
    jdbc {
      url = ${jdbcurl}
      user = "dev"
      password = "dev"
    }
  }
}

docspell.joex {
  jdbc {
    url = ${jdbcurl}
    user = "dev"
    password = "dev"
  }
  scheduler {
    pool-size = 1
  }
}
```

## ADRs

Some early information about certain details can be found in the few
[ADR](https://adr.github.io/) that exist:

- [ADRs](dev/adr.html)
