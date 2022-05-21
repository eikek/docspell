+++
title = "Control Runtime"
insert_anchor_links = "right"
description = "Control how addons are run"
weight = 30
template = "docs.html"
+++

# Control runtime of addons

Addons are run by the joex component as background tasks in an
external process. Depending on the machine it is running on, the addon
can be run

- inside a docker container
- inside a systemd-nspawn container
- directly on the machine

Addons can be provided as source packages, where the final program may
need to be built. They also can depend on other software. In order to
not prepare for each addon, it is recommended to install
[nix](https://nixos.org) with [flakes](https://nixos.wiki/wiki/Flakes)
and docker on the machine running joex.

Please also look at addon section in the [default
configuration](@/docs/configure/defaults.md#joex) for joex.

You need to explicitly enable addons in the restserver config file.

Docspell uses "runners" to execute an addon. This includes building it
if necessary. The following runner exist:

- `docker`: uses docker to build an run the addon
- `nix-flake`: builds via `nix build` and runs the executable in
  `$out/bin`
- `trivial`: simply executes a file inside the addon (as specified in
  the descriptor)

In the joex configuration you can specify which runners your system
supports.

## Prepare for *running* addons

Depending on how you want addons to be run, you need to install either
docker and/or systemd-nspawn on the machine running joex.
Additionally, the user running joex must be able to use these tools.
For docker it usually means to add the user to some group. For
systemd-nspawn you most likely want to configure `sudo` to run
passwordless the `systemd-nspawn` command.

Without this, an addon can only be run "directly" on the machine that
hosts joex (which might be perfectly fine). The addon then "sees" all
files on the machine and could potentially do harm.

It is recommended to install `nix` and `docker`, if possible. Addons
may only run with docker or only without, so supporting both leaves
more options.


## Prepare for *building* addons

Addons can be packaged as source or binary packages. For the former,
joex will build the addon first. There are two supported ways to do
so:

- via `docker build` when the addons provides a `Dockerfile` (use
  runner `docker`)
- via `nix build` when the addon provides a `flake.nix` file (use
  runner `nix-flake`)

Both build strategies will cache the resulting artifact, so subsequent
builds will be (almost) no-ops.

{% infobubble(title="Note") %}
*Building* addons requires to be connected to the internet! Running
them may not require a network connection.
{% end %}

If the addon is packaged as a binary, then usually the `trivial`
runner (possibly in combination with `systemd-nspawn`) can be used.

# Runtime

## Cache directory

Addons can use a "cache directory" to store data between runs. This
directory is not cleaned by docspell. If you have concerns about
space, use a cron job or systemd-timer to periodically clean this
directory.

## "Pure" vs "Impure"

Addons can talk back to Docspell in these ways: they can use the http
api, for example with [dsc](@/docs/tools/cli.md), or they can return
data to instruct Docspell to apply changes.

The former requires the addon to be connected to the network to reach
the Docspell *restserver*. This allows the addon to do arbitrary
changes at any time - this is the "impure" variant.

The second approach can be run without network connectivity. When
using docker or systemd-nspawn, Docspell will run these addons without
any network. Thus they can't do anything really, except return data
back to Docspell.

The pure way is much preferred! It allows for more consistent
behaviour, because Docspell is in charge for applying any changes.
Docspell can apply changes *only if* the addon returned successfully.
Addons can also be retried on error, because no changes happened yet.

It's the decision of the addon author, how the addon will work. It
should document whether it is pure or impure. You can also look into
the descriptor and check for a `networking: false` setting. As the
server administrator, you can configure Docspell to only accept pure
addons.


## Runners

### nix flake runner

For addons providing a `flake.nix` this runner can build it and find
the file to execute. With this `flake.nix` file addons can declare how
they should be build and what dependencies are required to run them.

The resulting executable can be executed via `systemd-nspawn` in a
restricted environment or directly on the machine.

{% infobubble(title="Requires") %}
You need to install [nix](https://nixos.org) and enable
[flakes](https://nixos.wiki/wiki/Flakes) to use this runner.
{% end %}

### docker

Addons can provide a Dockerfile or an image. If no image is given,
`docker build` will be run to build an image from the `Dockerfile`.
Then `docker run` is used to run the addon.

{% infobubble(title="Requires") %}
You need to install `docker` to use this runner.
{% end %}

### trivial

Addons can simply declare a file to execute. Docspell can use
`systemd-nspawn` to run it in an restricted environment, or it can be
run directly on the machine. This variant is only useful for very
simple addons, that don't require any special dependencies.

{% infobubble(title="Requires") %}
You need to check each addon for its requirements and prepare the
machine accordingly.
{% end %}

### Choosing runners

The config `addons.executor-config.runners` accepts a list of runners.
It specifies the preferred runner first. If an addon can be executed
via docker and nix, Docspell will choose the runner first in the list.

If you don't have nix installed, remove the `nix-flake` runner from
this list and same for docker, of course.


### systemd-nspawn

The `systemd-nspawn` can be used to run programs in a lightweight
ad-hoc container. It is available on most linux distributions (it is
part of systemd…). It doesn't require an image to exist first; this
makes it very convenient for running addons in a restricted
environment.

If you enable it in the config file, then all addons are either run
via `systemd-nspawn` or docker - and thus always in a restricted
environment, where they can only access their own files and the files
provided by Docspell.

The downside is that `systemd-nspawn` needs to be run as root (as far
as I know). Therfore, configure `sudo` to allow the user that is
running joex to execute `systemd-nspawn` non-interactively.

{% infobubble(title="Requires") %}
Install `systemd-nspawn` and enable the user running joex to use it
password-less via sudo.
{% end %}

# Within Docker

If joex itself is run as a docker container, things get a bit
complicated. The default image for joex does not contain `nix`, so the
`nix-flake` runner cannot be used out of the box.

In order to use the `docker` runner, the container must be configured
to access the hosts docker daemon. On most systems this can be
achieved by bind-mounting the unix socket (usually at
`/var/run/docker.sock`) into the container. Here is a snippet from the
provided `docker-compose` file:

```yaml
  joex:
    image: docspell/joex:latest
    # ... left out for brevity
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp:/tmp
```

Additionally to `/var/run/docker.sock`, it also bind mounts the `/tmp`
directory. This is necessary, because docker will be invoked with bind
mounts from inside the continer - but these must be available on the
host, because the docker client in the container actually runs the
command on the host.

The addon executor uses the systems temp-directory (which is usually
`/tmp`) as a base for creating a working and cache directory. Should
you change this in joex config file (or your system uses a different
default temp-dir), then the bind mount must be adapted as well.

Another variant is to extend the default joex image and add more
programs as needed by addons and then use the `trivial` runner.

# Summary / tl;dr

When joex is not inside a container:

- (optional) Install `systemd-nspawn` - it is provided on many
  GNU/Linux distributions
- Configure `sudo` to allow the user running the joex component to
  execute `systemd-nspawn` non-interactively (without requiring a
  password)
- Install docker
- Install [nix](https://nixos.org) and enable
  [flakes](https://nixos.wiki/wiki/Flakes)
- Allow the user who runs the joex component to use docker and nix. If
  you install nix as multi-user, then this is already done.
- Check the section on addons in the [default
  configuration](@/docs/configure/defaults.md#joex) for joex
