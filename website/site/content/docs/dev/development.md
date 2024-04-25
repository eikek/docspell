+++
title = "Tips & Setup"
weight = 20
+++

# Setup / Tips

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

``` bash
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

## Installing Nix

It is recommended to install [nix](https://nixos.org/nix). You can use
the official installer or [this
one](https://github.com/DeterminateSystems/nix-installer), which will
enable Flakes by default.

If not enabled, enable flakes by creating a config file:

```
mkdir -p ~/.config/nix  #on Linux
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

With nix installed you can use the provided development environments
to get started quickly.

# Nix Expressions

The soure root contains a `flake.nix` file to install docspell via the
nix package manager and to integrate it into NixOS.

The flake provides docspell packages of the latest release and NixOS
modules. It doesn't provide package builds from the current source
tree.

## Dev Environments

Additionally it provides devshells that can be used to create a
development environment for docspell.

These two `devShell` definitions address two different setups: one
uses a NixOS container and the other a VM. Both provide the same set
of services that can be used with the local docspell instance:

- postgresql database, with a database `docspell` and user `dev`
- solr with a core `docspell`
- email setup with smtp/imap and webmail
- minio with root user `minioadmin`

If you are on NixOS the container is probably more convenient to use.
For other systems, the vm should be good. Drop into either shell by
running:

``` bash
# drop into the environment setup for using a vm
nix develop .#dev-vm

# drop into the environment setup for using a container
nix develop .#docsp-dev
```

Once in such an environment, you can create the container or vm like
this:

```bash
# dev-vm env
# - build the vm
vm-build

# -run the vm
vm-run

# - ssh into the vm
vm-ssh

# docsp-dev container env
# - create the container
cnt-recreate

# - login
cnt-login
```

You can use tab completion on `vm-` or `cnt-` and see other useful
commands. For instance it allows to recreate solr cores or check logs
of services on the container or vm.

Then you can adjust your dev config file in `local/dev.conf` to
connect to the services on the vm or container. The container exposes
the default ports while the vm uses port-forwarding from the host to
the guest machine. The ports are define in `flake.nix`. For example, a
jdbc connection to postgres on the container can look like this:

```
jdbc.url = "jdbc:postgresql://docsp-dev:5432/docspelldev"
```

on the vm, it would be
```
jdbc.url = "jdbc:postgresql://localhost:6543/docspelldev"
```

You can reach the webmail on both versions at port `8080`. In order to
enable sending mails between users, you need to login as some
arbitrary user so the underlying services can create the data
directories. In your dev docspell you can then connect to smtp on the
vm or container. Mails send from docspell can be checked in the
webmail. Conversely, you can send mails using webmail to any user and
have their mailbox scanned by docspell.

### Direnv

Using [direnv](https://direnv.net) entering the dev environment is
very convenient. Install this tool (it also has integration in several
IDEs and editors) and create a file `.envrc` in the source root:

```
use flake .#<env-name>
```

The file `.envrc` is git-ignored, because different ones are possible.
Here `<env-name>` refers to either `dev-cnt` or `dev-vm` - one of the
devshells defined in `flake.nix`.

After allowing direnv to execute this file via `direnv allow` you will
be dropped into this environment whenever you enter the directory. It
will also preserve your shell, don't need to use bash.

## Checks

The command `nix flake check` would run all checks defined in the
flake. It will build both packages and runs a vm with docspell
installed (via NixOS modules) and check whether the services come up.

## Test VM

There is another VM defined in the flake that provides a full setup
for docspell. It contains docspell server and joex, a postgresql, a
solr and a email setup. The intention is to use it as an easy 'getting
started' approach with nix.

Once it has started, you can connect to `localhost:7881` to reach
docspell. The webmail will be available at `localhost:8080`.

You can run this vm with a single command:

```
nix run github:eikek/docspell#nixosConfigurations.test-vm.config.system.build.vm
```

It uses the same setup as the dev-vm, so you can drop into the
`.#dev-vm` development shell and use `vm-ssh` to connect to the
running test vm.

Once connected to the machine, you can see the docspell config file via

```bash
systemctl show docspell-joex.service | grep "ExecStart=" | sed 's/^ExecStart=.*path=\([^;]*\).*/\1/' | xargs tac | grep -m 1 . | awk '{print $NF}' | tr -d '"' | xargs jq '.'
# or replace "joex" with "restserver"
systemctl show docspell-restserver.service | grep "ExecStart=" | sed 's/^ExecStart=.*path=\([^;]*\).*/\1/' | xargs tac | grep -m 1 . | awk '{print $NF}' | tr -d '"' | xargs jq '.'
```

# Developing Frontend

The frontend is a SPA written in [Elm](https://elm-lang.org). The UI
framework in use is [tailwind](https://tailwindcss.com).

The frontend code is in the sub-project `webapp`. Running sbt's
`compile` task, compiles elm sources and creates the final CSS file.
Whenever the `restserver` module is build by sbt, the `webapp`
sub-project is built as well and the final files to deliver are
updated. So, when in sbt shell, "watch-compile" the project
`restserver`, (via `~ restserver/compile`), re-compiles elm-code on
change. However, it also re-creates the final css, which is a rather
long task.

To speed things up when only developing the frontend, a bash script is
provided in `project/dev-ui-build.sh`. Start the `restserver` once,
using `restserver/reStart` task as described above. Then run this
script in the source root. It will watch elm files and the css file
and re-compiles only on change writing the resulting files in the
correct locations so they get picked up by the restserver.

Now you can edit elm files and the `index.css` and then only refresh
the page. Elm compilation is *very* fast, it's difficult to reach the
refresh button before it is done compiling :). When editing the CSS,
it takes a little longer, but this is hardly necessary, thanks to
tailwind.

There is still a problem: the browser caches the js and css files by
default, so a page refresh is not enough, you need to clear the cache,
too. To avoid this annoyance, set a env variable `DOCSPELL_ENV` to the
value `dev`. Docspell then adds a response header, preventing the
browser to cache these files. This must be done, obviously, before
starting the restserver:

``` bash
$ export DOCSPELL_ENV=dev
$ sbt "restserver/reStart"
```

# Developing Backend

## OpenAPI

The http API is specified in the corresponding `-openapi.yml` file.
The `component` section is being used to generate code for the client
and the server, so that both are always in sync. However, the route
definitions are not checked against the server implementation.

Changes to the openapi files can be checked by running a sbt task:

``` scala
restapi/openapiLint //and/or
joexapi/openapiLint
```

These tasks must not show any errors (it is checked by the CI). The
warnings should also be fixed.


# Release

The CI and making a release is done via github actions. The workflow
is roughly like this:

- each PR is only merged if the `sbt ci` task returns successfully.
  This is ensured by the `ci.yml` workflow that triggers on each pull
  request
- each commit to the `master` branch is also going through `sbt ci`
  and then a prerelease is created. The tag `nightly` is used to point
  to the latest commit in `master`. Note, that this is [discouraged by
  git](https://git-scm.com/docs/git-tag#_on_re_tagging), but github
  doesn't allow to create a release without a tag. So this tag moves
  (and is not really a tag then…). After the prerelease is created,
  the docker images are built and pushed to docker hub into the
  [docspell](https://hub.docker.com/u/docspell) organization. The
  docker images are also tagged with `nightly` at docker hub. This is
  all done via the `realease-nightly.yml` workflow.
- A stable release is started by pushing a tag with pattern `v*` to
  github. This triggers the `release.yml` workflow which builds the
  packages and creates a release in *draft mode*. The `sbt ci` task
  *is not* run, because it is meant to only release commits already in
  the `master` branch. After this completes, the release notes need to
  be added manually and then the release must be published at github.
  This then triggers the `docker-images.yml` workflow, which builds
  the corresponding docker images and pushes them to docker hub. The
  docker images are tagged with the exact version and the `latest` tag
  is moved to the new images. Another manual step is to set the branch
  `current-docs` to its new state and push it to github. This will
  trigger a build+publish of the website.
- Publishing the website happens automatically on each push to the
  branch `current-docs`. Changes to the current website must be based
  on this branch.

Some notes: I wanted a 2/3 step process when doing a stable release,
to be able to add release notes manually (I don't want this to be
automated right now) and to do some testing with the packages before
publishing the release. However, for the nightly releases, this
doesn't matter - everything must be automated here obviously. I also
wanted the docker images to be built from the exact same artifacts
that have been released at github (in contrast to being built again).
