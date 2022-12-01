+++
title = "Nix / NixOS"
weight = 24
+++

# Nix

## Install via Nix

Docspell can be installed via the [nix](https://nixos.org/nix) package
manager, which is available for Linux and OSX. Docspell is currently not
part of the [nixpkgs collection](https://nixos.org/nixpkgs/), but you
can use the flake from this repository.

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
inputs.docspell.url = "github:eikek/docspell?dir=nix/";

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
