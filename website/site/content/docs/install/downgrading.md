+++
title = "Downgrading"
weight = 37
+++

Downgrading is currently not supported!

Note, it is not safe to install a previous version, because the
database will not be compatible. Therefore, it is recommended to take
a backup of the database before upgrading.

Should something not work out as expected, you need to restore the
backup and then go back to the previous version.

## Docker-Compose

The default `docker-compose.yml` file points to images using the
`-LATEST` tag. You need to edit this file and replace `-LATEST` with
the concrete version, like `-v0.20.0`.

Then run the three steps as when upgrading:

``` bash
$ docker-compose down
$ docker-compose pull
$ docker-compose up --force-recreate --build -d
```


## ZIP / Deb Files

Simply download a concrete version and re-install it using your
package manager or unpack the zip file.


## Nix

When using the provided nix setup, the `currentPkg` always points to
the latest version. But most other versions are also provided and can
be chosen from:

``` nix
# …
       docspell = callPackage (docspell.pkg docspell.cfg.v0_20_0) {};
# …
```
