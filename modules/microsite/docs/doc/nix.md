---
layout: docs
title: Nix/NixOS
permalink: doc/nix
---

# {{ page.title }}

## Install via Nix

Docspell can be installed via the [nix](https://nixos.org/nix) package
manager, which is available for Linux and OSX. Docspell is currently not
part of the [nixpkgs collection](https://nixos.org/nixpkgs/), but you
can use the derivation from this repository. This is sometimes
referred to as [import from
derivation](https://nixos.wiki/wiki/Import_From_Derivation).

For example, the `builtins.fetchTarball` function can be used to
retrieve the files; then import the `release.nix` file:

``` nix
let
  docspellsrc = builtins.fetchTarball "https://github.com/eikek/docspell/archive/master.tar.gz";
in
import "${docspellsrc}/nix/release.nix";
```

This creates a set containing a function for creating a derivation for
docspell. This then needs to be called like other custom packages. For
example, in your `~/.nixpkgs/config.nix` you could write this:

``` nix
let
  docspellsrc = builtins.fetchTarball "https://github.com/eikek/docspell/archive/master.tar.gz";
  docspell = import "${docspellsrc}/nix/release.nix";
in
{ packageOverrides = pkgs:
   let
     callPackage = pkgs.lib.callPackageWith(custom // pkgs);
     custom = {
       docspell = callPackage docspell.currentPkg {};
     };
   in custom;
}
```

The `docspell` custom package is again a set that contains derivations
for all 3 installable docspell programs: the restserver, joex and the
tools.

Then you can install docspell via `nix-shell` or `nix-env`, for example:

``` bash
$ nix-env -iA nixpkgs.docspell.server nixpkgs.docspell.joex nixpkgs.docspell.tools
```

You may need to replace `nixpkgs` with `nixos` when you're on NixOS.

The expression `docspell.currentPkg` refers to the most current release
of Docspell. So even if you use the tarball of the current master
branch, the `release.nix` file only contains derivations for releases.
The expression `docspell.currentPkg` is a shortcut for selecting the
most current release. For example it translates to `docspell.pkg
docspell.cfg.v@PVERSION@` – if the current version is `@VERSION@`.


## Docspell as a service on NixOS

If you are running [NixOS](https://nixos.org), there is a module
definition for installing Docspell as a service using systemd.

There are the following modules provided:

- restserver
- joex
- consumedir

The `consumedir` module defines a systemd unit that starts the
`consumedir.sh` script to watch one or more directories for new files.

You need to import the `release.nix` file as described above in your
`configuration.nix` and then append the docspell module to your list of
modules. Here is an example:

```nix
{ config, pkgs, ... }:
let
  docspellsrc = builtins.fetchTarball "https://github.com/eikek/docspell/archive/master.tar.gz";
  docspell = import "${docspellsrc}/nix/release.nix";
in
{
  imports = [ mymodule1 mymodule2 ] ++ docspell.modules;

  nixpkgs = {
    config = {
      packageOverrides = pkgs:
        let
          callPackage = pkgs.lib.callPackageWith(custom // pkgs);
          custom = {
            docspell = callPackage docspell.currentPkg {};
          };
        in custom;
    };
  };

  services.docspell-restserver = {
    enable = true;
    base-url = "http://docspelltest:7880";
    # ... more settings here
  };
  services.docspell-joex = {
    enable = true;
    base-url = "http://docspelltexst:7878";
    # ... more settings here
  };
  services.docspell-consumedir = {
    enable = true;
    watchDirs = ["/tmp/test"];
    urls = ["http://localhost:7880/api/v1/open/upload/item/the-source-id"];
  };

  ...
}

```

Please see the `nix/module-server.nix` and `nix/module-joex.nix` files
for the set of options. The nixos options are modelled after the
default configuration file.

The modules files are only applicable to the newest version of
Docspell. If you really need an older version, checkout the
appropriate commit.

## NixOs Example

This is a example system configuration that installs docspell with a
postgres database. This snippet can be used to create a vm (using
`nixos-rebuild build-vm` as shown above) or a container, for example.

``` nix
{ config, pkgs, ... }:
let
  docspellsrc = builtins.fetchTarball "https://github.com/eikek/docspell/archive/master.tar.gz";
  docspell = import "${docspellsrc}/nix/release.nix";
in
{
  imports = docspell.modules;

  nixpkgs = {
    config = {
      packageOverrides = pkgs:
        let
          callPackage = pkgs.lib.callPackageWith(custom // pkgs);
          custom = {
            docspell = callPackage docspell.currentPkg {};
          };
        in custom;
    };
  };

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
