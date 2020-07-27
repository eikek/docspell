+++
title = "Quickstart"
weight = 0
+++

To get started, here are some quick links:

- Using [docker and
  docker-compose](@/docs/install/installing.md#docker). This sets up
  everything: all prerequisites, both docspell components and a
  container running the [consumedir.sh](@/docs/tools/consumedir.md)
  script to import files that are dropped in a folder.
- [Download, Unpack and
  Run](@/docs/install/installing.md#download-unpack-run). This option
  is also very quick, but you need to check the
  [prerequisites](@/docs/install/prereq.md) yourself. Database is
  already setup, but you'd need to setup SOLR (when using fulltext
  search) and install some programs for the joex component. This
  applies to the `zip` and `deb` files. The files can be downloaded
  from the [release page](https://github.com/eikek/docspell/releases/latest).
- via the [nix package manager](@/docs/install/installing.md#nix) and/or as a [NixOS
  module](@/docs/install/installing.md#nixos). If you use nix/nixos, you
  know what to do. The linked page contains some examples.
