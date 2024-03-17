+++
title = "Getting started"
weight = 0
+++

# Getting started

To get started, here are some quick links:

- Using [docker and docker-compose](@/docs/install/docker.md). This
  sets up everything: all prerequisites, both docspell components and
  a container running the [dsc
  watch](@/docs/tools/cli.md#watch-a-directory) script to import files
  that are dropped in a folder.
- [Download, Unpack and Run](@/docs/install/download_run.md). This
  option is also very quick, but you need to check the
  [prerequisites](@/docs/install/prereq.md) yourself. Database is
  already setup, but you'd need to setup SOLR (when using fulltext
  search) and install some programs for the joex component. This
  applies to the `zip` and `deb` files. The files can be downloaded
  from the [release
  page](https://github.com/eikek/docspell/releases/latest).
- via the [nix package manager](@/docs/install/nix.md#try-it-out)
  and/or as a [NixOS module](@/docs/install/nix.md#nixos) through a
  flake. If you use nix/nixos, you know what to do. The linked page
  contains some examples.
- [Unraid](https://www.unraid.net/): There are user provided [notes
  and unraid
  templates](https://github.com/vakilando/unraid-docker-templates)
  which can get you started. There is also an [installation and help
  thread](https://forums.unraid.net/topic/103425-docspell-hilfe/) in
  the German Unraid forum. Thanks for providing these!

Every [component](@/docs/_index.md#components) (restserver,
joex, dsc watch) can run on different machines and multiple times.
Most of the time running all on one machine is sufficient and also for
simplicity, the docker-compose setup reflects this variant.

While there are many different ways to run docspell, at some point all
call docspell binaries. These accept one argument: a [config
file](@/docs/configure/_index.md). If this is not given, the default
is used, which gets you started on a single machine, but it is very
likely you want to change these to match your use-case/setup.

{% infobubble(title="Note") %}

Please have a look at the [configuration page](/docs/configure/) page,
before making docspell publicly available. By default, everyone can
create an account. This is great for trying out and using it in an
internal network. But when opened up to the outside, it is recommended
to lock this down.

{% end %}
