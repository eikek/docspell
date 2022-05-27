+++
title = "Writing"
insert_anchor_links = "right"
description = "How to write addons"
weight = 20
template = "docs.html"
+++

# Writing Addons

Writing an addon can be divided into two things:

- create the program
- define how to package and run it

The next sections describe both parts. For a quick start, check out
the example addons.

As previously written, you can choose a language. The interaction with
docspell happens by exchanging JSON data. So, whatever you choose, it
should be possible to read and produce JSON with some convenience.


# Writing the program

## Interface to Docspell

The interface to Docspell is JSON data. The addon receives all inputs
as JSON and may return a JSON object as output (via stdout).

An addon can be executed in different contexts. Depending on this, the
available inputs differ. The addon always receives one argument, which
is a file containing the user supplied data (it may be empty). A user
is able to provide data to every addon from the web-ui.

All other things are provided as environment variables. There are
environment variables that are always provided and some are only
available for specific contexts.

For example, an addon that is executed in the context of an item
(maybe after processing or when a user selects an addon to run "on an
item"), Docspell prepares all data for the corresponding item and
makes it available to the addon. In contrast, an addon executed
periodically by a schedule, won't have this data available.


## Basic Environment

The following environment variables are always provided by Docspell:

- `ADDON_DIR` points to the directory containing the extracted addon
  zip file
- `TMPDIR` / `TMP_DIR` a directory for storing temporary data
- `OUTPUT_DIR` a directory for storing files that should be processed
  by docspell
- `CACHE_DIR` a directory for storing data that should stay between
  addon runs

It is very much recommended to always use these environment variables
when reading and writing data. This keeps Docspell in control about
the exact location.

The working directory will be set to a directory that is also
temporary, but please don't rely on that. Use the environment
variables.

## Item data

When executed in the context of an item. Meaning for triggers:
`final-process-item`, `final-reprocess-item`, `existing-item`.

### `ITEM_DATA_JSON`

This environment variable points to a JSON file containing information
about the current item. If it is run at processing time, it includes
all information gathered so far by Docspell.

**Example**
{{ incl_json(path="templates/shortcodes/item-data") }}


### `ITEM_ARGS_JSON`

This environment variable points to a JSON file that contains the user
supplied information with an upload request. That is, a user may
specify tags or a language when uploading files. This would be in this
file.

*This is only available for uploads. Trigger `final-process-item`.*

**Example**
{{ incl_json(path="templates/shortcodes/item-args") }}


### `ITEM_ORIGINAL_JSON` and `ITEM_PDF_JSON`

These JSON files contains a list of objects. Each object provides
properties about a file - either the original file or the converted
pdf. The structure is the same.

**Example**
{{ incl_json(path="templates/shortcodes/file-meta") }}



### Directories

These environment variables point to directories that contain the attachment files.

- `ITEM_PDF_DIR` contains all converted pdf files, the attachment id is the filename
- `ITEM_ORIGINAL_DIR` contains all original files, the attachment id is the filename

For example, to obtain a converted pdf file, lookup the id in
`ITEM_PDF_JSON` and then construct the file name via
`ITEM_PDF_DIR/{id}`.


## Session for dsc

An addon may use [dsc](@/docs/tools/cli.md) which requires for many
commands a valid session identifier. Usually this is obtained by
logging in (i.e. using `dsc login`). This is not really feasible from
inside an addon, of course. Therefore you can configure an addon to
run on behalf of some user when creating the run configuration.
Docspell then generates a valid session identifier and puts it into
the environment. The [dsc](@/docs/tools/cli.md) tool will pick them up
automatically.

It will also setup the URL to connect to some restserver. (If you have
multiple rest-servers running, it will pick one randomly).

- `DSC_SESSION` env variable containing a session identifier. It's
  validity is coupled on the configured timeout.
- `DSC_DOCSPELL_URL` the base url to some rest server

That means when using an addon in this way, you can simply use `dsc`
without worrying about authentication or the correct URL to connect
to.


## Output

Docspell doesn't interpret the returncode of an addon, except checking
for being equal to `0` which indicates a successful run.

In order to do change data in Docspell, the addon program can run
`dsc` (for example) to change some state - like setting tags etc. But
the preferred approach would be to return instructions for Docspell.
Docspell will execute the instructions when the addon terminates
successfully - that is with return code `0`.

These instructions are in a JSON object which needs to go to stdout.
You can use stderr in an addon for logging/debugging purposes. But if
you specify `collectOutput: true` in the descriptior, then stdout must
only return this specific JSON (or nothing, empty output is ignored).

You find the complete structure below. It consists of these parts:

- `commands`: let's you declare actions to do for an item or attachment
- `files`: defines files relative to `OUTPUT_DIR` that should be
  processed
- `newItems`: declares files relative to `OUTPUT_DIR` that should be
  processed as new uploads

The `commands` allows to set tags, fields and other things. All parts
are optional, you don't need to return the complete structure. Just
returning `commands` or only `files` is ok.

**Example**
{{ incl_json(path="templates/shortcodes/addon-output") }}


# Descriptor

An addon must provide an *addon descriptior*, which is a yaml or json
file looking like this:

```yaml
# The meta section is required. Name and version must not contain
# whitespace
meta:
  name: "name-of-addon"
  version: "2.21"
  description: |
    Describe the purpose and how it must be used here

# Defining when this addon is run. This is used to guide the user
# interface in selecting an addon. At least one is required to specify.
#
# Possible values:
# - scheduled: requires to enter a timer to run this addon periodically
# - final-process-item: the final step when processing an item
# - final-reprocess-item: the final step when reprocessing an item
# - existing-item: A user selects the addon to run on an item
triggers:
  - final-process-item
  - final-reprocess-item
  - existing-item

# How to build and run this addon (optional). If missing, auto
# detection will enable a nix runner if a `flake.nix` is found in the
# source root and docker if a `Dockerfile` is found.
#
# Both runners are compared to what is enabled at the server.
runner:
  # Building the program using nix flakes. This requires a flake.nix
  # file in the source root with a default package and a flake-enabled
  # nix on the joex machine.
  #
  # The program is build via `nix build`. If the joex machine has
  # systemd-nspawn installed, it is used to run the addon inside a
  # container. Otherwise the addon is run directly on the machine.
  nix:
    enable: true

  # Docker based runner can define a custom image to use. If a `build`
  # key exists pointing to a Dockerfile, the image is build before. If
  # the docker image is complex, you can build it independently and
  # provide the pre-build image.
  #
  # The program is run via `docker run` passing the arguments to the
  # addon. Thus it expects the entrypoint to be correctly configured
  # to the executable. You may use `args` in order to prepend
  # additional arguments, like the path to an executable if the image
  # requires that. The joex machine must have docker installed and the
  # user running joex must be allowed to use docker. You must either
  # define an image with an appropriate entry point or a dockerfile.
  docker:
    enable: false
    #image: myorg/myimage:latest
    build: Dockerfile

  # Trivial runner that simply executes the file specified with
  # `exec`. Nothing is build before. This runner usually requires that
  # the joex machine contains all dependencies needed to run the
  # addon. You may need to install additional software on the machine
  # running joex.
  trivial:
    enable: false
    exec: src/addon.sh

# Optional arguments/options given to the program. The program
# receives at least one argument, which is a file to the user input as
# supplied in the application. The arguments here are prepended.
args:


options:
  # If false, the program is run inside a private network, blocking
  # traffic to the host and networks reachable from there. This only
  # applies if the addon can be run inside a container.
  #
  # If the addon runs side effects (such as using dsc to set tags),
  # this must be set to `true`.
  #
  # Default is false.
  networking: true

  # If true, the stdout of the program is parsed into a JSON structure
  # that is interpreted as actions executed by the task that runs the
  # addon. If the addon runs side effects only, set this to `false`
  # and the output is ignored.
  #
  # It is recommended to use this approach, if possible. It allows
  # docspell itself to apply any changes and the addon can run
  # completely isolated.
  #
  # Default is true.
  collectOutput: true
```


# Packaging

Docspell can use different ways to build and run the addon:
`nix-flake`, `docker` and `trivial`. The first two allow to package
the addon in a defined way (with a single dependency, either nix or
docker) and then execute it independently from the underlying system.
This makes it possible to execute the addon on a variety of systems.
This is especially useful for addons that are meant to be public and
reusable by different people.

The "trivial" runner is only executing some program specified in
`docspell-addon.yaml`, directly on the joex machine (or via
`systemd-nspawn`). The machine running joex must then provide all
necessary dependencies and it must be compatible to run the addon. It
may be useful especially for personal addons.


## nix flake

Using [nix](https://nixos.org) with
[flakes](https://nixos.wiki/wiki/Flakes) enabled, is the recommended
approach. It is very flexible and reproducible while sharing most
dependencies (in contrast to docker where each image contains the same
packages again and again).

Docspell runs `nix build` to build the addon and then executes the
file produced to `$out/bin`.


## docker

For docker it is recommended to provide pre-build images. Docspell can
build images from provided `Dockerfile`, but for larger images it
might be better to do this apriori.

Docspell will run the addon using `docker run …` passing it only the
user-input file as argument. Thus the image must define an appropriate
`ENTRYPOINT`.

# Examples
## Minimal Addon

The steps below create a minimal addon:

1. Create a bash script `addon.sh` with this content:

   ```bash
   #!/usr/bin/env bash

   echo "Hello world!"
   ```
2. Make it executable:
   ```bash
   chmod +x addon.sh
   ```
3. Create a yaml file `docspell-addon.yaml` with this content:

   ```yaml
   meta:
     name: "minimal-addon"
     version: "0.1.0"
   triggers:
     - existing-item
     - scheduled
   runner:
     trivial:
       enable: true
       exec: addon.sh
   ```
4. Create a zip file containing these two files:
   ```bash
   zip addon.zip docspell-addon.yaml addon.sh
   ```

The addon is now ready. Make it available via an url (use some file
sharing tool, upload it somewhere etc) and then it can be installed
and run.

## Non-Minimal Addon

The minimal example above is good to see what is required, but it is
not very useful…. Please see this post about the [audio file
addon](@/blog/2022-05-16_audio_file_addon.md) that walks through a
more useful addon.

# Misc

## Advantages of "pure" addons

Although the output structure is not set in stone, it is recommended
to use this in contrast to directly changing state via `dsc`.

- outputs of all addons are collected and only applied if all were
  successful; in contrast side effects are always applied even if the
  addon fails shortly after
- since addons are executed as joex tasks, their result can be send as
  events to another http server for further processing.
- addons can run in an isolated environment without network (no data
  can go out)

## Use addons in other addons?

This can be achieved very conveniently by using `nix`. If addons are
defined as a nik flake, they can be easily consumed by each other.
