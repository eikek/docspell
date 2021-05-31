+++
title = "Tips & Setup"
weight = 20
+++

# Starting Servers with `reStart`

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


# Custom config file

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

# Nix Expressions

The directory `/nix` contains nix expressions to install docspell via
the nix package manager and to integrate it into NixOS.

## Testing NixOS Modules

The modules can be build by building the `configuration-test.nix` file
together with some nixpkgs version. For example:

``` bash
nixos-rebuild build-vm -I nixos-config=./configuration-test.nix \
  -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz
```

This will build all modules imported in `configuration-test.nix` and
create a virtual machine containing the system. After that completes,
the system configuration can be found behind the `./result/system`
symlink. So it is possible to look at the generated systemd config for
example:

``` bash
cat result/system/etc/systemd/system/docspell-joex.service
```

And with some more commands (there probably is an easier way…) the
config file can be checked:

``` bash
cat result/system/etc/systemd/system/docspell-joex.service | grep ExecStart | cut -d'=' -f2 | xargs cat | tail -n1 | awk '{print $NF}'| sed 's/.$//' | xargs cat | jq
```

To see the module in action, the vm can be started (the first line
sets more memory for the vm):

``` bash
export QEMU_OPTS="-m 2048"
export QEMU_NET_OPTS "hostfwd=tcp::7880-:7880"
./result/bin/run-docspelltest-vm
```

# Release

The CI and making a release is done via [github
actions](https://docs.github.com/en/actions). The workflow is roughly
like this:

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


# Background Info

There is a list of [ADRs](@/docs/dev/adr/_index.md) containing
internal/background info for various topics.
