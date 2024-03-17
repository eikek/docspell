+++
title = "Nix / NixOS"
weight = 24
+++

# Nix

Docspell is a flake, you need to enable flakes in order to make use of
it. You can also use the provided expressions without Flakes, which is
described below.

## Try it out {try-it-out}

You can try out the server and joex packages by running the following:

```
nix run github:eikek/docspell#docspell-restserver
nix run github:eikek/docspell#docspell-joex
```

While this works, it will be only a very basic setup. The database
defaults to a directory in `/tmp` and no fulltext search enabled. Then
for processing documents, some external tools are required which would
need to be present on yout system to make it work.

A more elaborate setup with PostgreSQL and SOLR can be started using
the `test-vm`:

```
nix run github:eikek/docspell#nixosConfigurations.test-vm.config.system.build.vm
```

The vm contains all the required tools. After starting up, you can
find docspell at `http://localhost:7881`.

## Install via Nix

Docspell can be installed via the [nix](https://nixos.org/nix) package
manager. Docspell is currently not part of the [nixpkgs
collection](https://nixos.org/nixpkgs/), but you can use the flake
from this repository.

You could install the server and joex by running the following:
```
nix profile install github:eikek/docspell#docspell-restserver
nix profile install github:eikek/docspell#docspell-joex
```

This would install the packages on your system. If you use NixOS you
probably want to use the provided [NixOS modules](#nixos) instead.


## Upgrading

Since [downgrading](@/docs/install/downgrading.md) is not supported,
it is recommended to backup your database before upgrading. Should
something not work as expected, restore the database backup and go
back to the previous version.

# Docspell on NixOS {#nixos}

If you are running [NixOS](https://nixos.org), there is a module
definition for installing Docspell as a service using systemd.

There are the following modules provided:

- restserver
- joex

```nix
# flake.nix
inputs.docspell.url = "github:eikek/docspell";

# in modules
imports = [ 
      docspell.nixosModules.default
]

services.docspell-joex = { ...  }
services.docspell-restserver = { ...  }
```

Please see the `nix/modules/server.nix` and `nix/modules/joex.nix` files
for the set of options. The nixos options are modeled after the
default configuration file.

The modules files are only applicable to the newest version of
Docspell. If you really need an older version, checkout the
appropriate commit.

## NixOS Example

This is a example system configuration that installs docspell with a
postgres database. This snippet can be used to create a vm (using
`nixos-rebuild build-vm` as shown above) or a container, for example.

``` nix
# flake.nix
inputs.docspell.url = "github:eikek/docspell?dir=nix/";

# module.nix
{ config, pkgs, docspell, ... }:
{
  imports = docspell.nixosModules.default;

  ##### just for the example…
  users.users.root = {
    password = "root";
  };
  #####

  # install docspell-joex and enable the systemd service
  services.docspell-joex = {
    enable = true;
    base-url = "http://localhost:7878";
    bind = {
      address = "0.0.0.0";
      port = 7878;
    };
    scheduler = {
      pool-size = 1;
    };
    jdbc = {
      url = "jdbc:postgresql://localhost:5432/docspell";
      user = "docspell";
      password = "docspell";
    };
  };

  # install docspell-restserver and enable the systemd service
  services.docspell-restserver = {
    enable = true;
    base-url = "http://localhost:7880";
    bind = {
      address = "0.0.0.0";
      port = 7880;
    };
    auth = {
      server-secret = "b64:EirgaudMyNvWg4TvxVGxTu-fgtrto4ETz--Hk9Pv2o4=";
    };
    backend = {
      signup = {
        mode = "invite";
        new-invite-password = "dsinvite2";
        invite-time = "30 days";
      };
      jdbc = {
        url = "jdbc:postgresql://localhost:5432/docspell";
        user = "docspell";
        password = "docspell";
      };
    };
  };

  # install postgresql and initially create user/database
  services.postgresql =
  let
    pginit = pkgs.writeText "pginit.sql" ''
      CREATE USER docspell WITH PASSWORD 'docspell' LOGIN CREATEDB;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO docspell;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO docspell;
      CREATE DATABASE DOCSPELL OWNER 'docspell';
    '';
  in {
      enable = true;
      package = pkgs.postgresql_11;
      enableTCPIP = true;
      initialScript = pginit;
      port = 5432;
      authentication = ''
        host  all  all 0.0.0.0/0 md5
      '';
  };

  networking = {
    hostName = "docspellexample";
    firewall.allowedTCPPorts = [7880];
  };
}
```

You can also look at `nix/test-vm.nix` for another example.

## Without Flakes

Of course, you can also use it without flakes. There is `nix/pkg.nix`
which contains the derivation of both packages, `docspell-restserver` and
`docspell-joex`. Just call it with your nixpkgs instance as usual:

``` nix
let 
  repo = fetchurl {
    url = "https://github.com/eikek/docspell";
    sha256 = "sha256-X2mM+Z5s8Xm1E6zrZ0wcRaivLEvqbk5Dn+GSXkZHdLM=";
  };
  docspellPkgs = pkgs.callPackage (import "${repo}/nix/pkg.nix") {};
in
 #
 # use docspellPkgs.docspell-restserver or docspellPkgs.docspell-joex
 #
```

The same way import NixOS modules from
`nix/modules/{joex|server}.nix`.

An alternative can be to use `builtins.getFlake` to fetch the flake
and get access to its output. But this requires to use a flake enabled
nix, which then defeats the idea of "not using flakes".
