---
layout: docs
title: Development
permalink: dev
---


# {{page.title}}


## Building

[Sbt](https://scala-sbt.org) is used to build the application. Clone
the sources and run:

- `make` to compile all sources (Elm + Scala)
- `make-zip` to create zip packages
- `make-deb` to create debian packages
- `make-tools` to create a zip containing the script in `tools/`
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

It is possible to start both in the root project:

```
sbt:docspell-root> reStart
```


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

## Nix Expressions

The directory `/nix` contains nix expressions to install docspell via
the nix package manager and to integrate it into NixOS.

### Testing NixOS Modules

The modules can be build by building the `configuration-test.nix` file
together with some nixpkgs version. For example:

``` shell
nixos-rebuild build-vm -I nixos-config=./configuration-test.nix \
  -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz
```

This will build all modules imported in `configuration-test.nix` and
create a virtual machine containing the system. After that completes,
the system configuration can be found behind the `./result/system`
symlink. So it is possible to look at the generated systemd config for
example:

``` shell
cat result/system/etc/systemd/system/docspell-joex.service
```

And with some more commands (there probably is an easier way…) the
config file can be checked:

``` shell
cat result/system/etc/systemd/system/docspell-joex.service | grep ExecStart | cut -d'=' -f2 | xargs cat | tail -n1 | awk '{print $NF}'| sed 's/.$//' | xargs cat | jq
```

To see the module in action, the vm can be started (the first line
sets more memory for the vm):

``` shell
export QEMU_OPTS="-m 2048"
./result/bin/run-docspelltest-vm
```
