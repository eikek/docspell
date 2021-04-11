+++
title = "Upgrading"
weight = 35
+++

Upgrading docspell requires to download the newer binaries and
re-installing them depending on your setup.

The database is migrated on application start automatically.

Since [downgrading](@/docs/install/downgrading.md) is not supported,
it is recommended to backup your database before upgrading. Should
something not work as expected, restore the database backup and go
back to the previous version.

# Docker-Compose

When using the provided `docker-compose` setup, you only need to pull
the new images. The latest release is always tagged with `-LATEST`.

``` bash
$ docker-compose down
$ docker-compose pull
$ docker-compose up --force-recreate --build -d
```

# Zip / Deb Files

When using the zip or deb files, either install the new deb files via
your package manager or download and unpack the new zip files.

# Nix

When using the provided nix setup, the `currentPkg` always points to
the latest release. Thus it is enough to run `nix-build`.
