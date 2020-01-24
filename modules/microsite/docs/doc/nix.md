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
