+++
title = "Installing"
weight = 20
+++

# Docker

There is a [docker-compose](https://docs.docker.com/compose/) setup
available in the `/docker` folder. This setup is also taking care of
all the necessary [prerequisites](@/docs/install/prereq.md) and
creates a container to watch a directory for incoming files. It's only
3 steps:

1. Clone the github repository
   ```bash
   $ git clone https://github.com/eikek/docspell
   ```
   If you don't have git or don't want to clone the whole repo, use these steps instead:
   ``` bash
   mkdir -p docspell/docker
   cd docspell/docker
   wget https://raw.githubusercontent.com/eikek/docspell/master/docker/docker-compose.yml
   wget https://raw.githubusercontent.com/eikek/docspell/master/docker/docspell.conf
   wget https://raw.githubusercontent.com/eikek/docspell/master/docker/.env
   ```
2. Change into the `docker` directory:
   ```bash
   $ cd docspell/docker
   ```
3. Run `docker-compose up`:

   ```bash
   $ export DOCSPELL_HEADER_VALUE="my-secret-123"
   $ docker-compose up
   ```

   The environment variable defines a secret that is shared between
   some containers. You can define whatever you like. Please see the
   [consumedir.sh](@/docs/tools/consumedir.md#docker) docs for
   additional info.
4. Goto `http://localhost:7880`, signup and login. When signing up,
   you can choose the same name for collective and user. Then login
   with this name and the password.

5. (Optional) Create a folder `./docs/<collective-name>` (the name you
   chose for the collective at registration) and place files in there
   for importing them.

The directory contains a file `docspell.conf` that you can
[modify](@/docs/configure/_index.md) as needed.

# Download, Unpack, Run

You can install via zip or deb archives. Please see the
[prerequisites](@/docs/install/prereq.md) first.

## Using zip files

You need to download the two files:

- [docspell-restserver-{{version()}}.zip](https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-restserver-{{version()}}.zip)
- [docspell-joex-{{version()}}.zip](https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-joex-{{version()}}.zip)


1. Unzip both files:
   ``` bash
   $ unzip docspell-*.zip
   ```
2. Open two terminal windows and navigate to the the directory
   containing the zip files.
3. Start both components executing:
   ``` bash
   $ ./docspell-restserver*/bin/docspell-restserver
   ```
   in one terminal and
   ``` bash
   $ ./docspell-joex*/bin/docspell-joex
   ```
   in the other.
4. Point your browser to: <http://localhost:7880/app>
5. Register a new account, sign in and try it.

Note, that this setup doesn't include watching a directory. You can
use the [consumedir.sh](@/docs/tools/consumedir.md) tool for this or
use the docker variant below.

## Using deb files

The DEB packages can be installed on Debian, or Debian based Distros:

``` bash
$ sudo dpkg -i docspell*.deb
```

Then the start scripts are in your `$PATH`. Run `docspell-restserver`
or `docspell-joex` from a terminal window.

The packages come with a systemd unit file that will be installed to
autostart the services.

# Nix

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

The expression `docspell.currentPkg` refers to the most current
release of Docspell. So even if you use the tarball of the current
master branch, the `release.nix` file only contains derivations for
releases. The expression `docspell.currentPkg` is a shortcut for
selecting the most current release. For example it translates to
`docspell.pkg docspell.cfg.v{{ pversion() }}` – if the current version
is `{{version()}}`.


## Docspell on NixOS {#nixos}

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

### NixOS Example

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
