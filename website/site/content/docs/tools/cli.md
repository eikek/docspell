+++
title = "CLI"
description = "A command line interface to."
weight = 5
+++

# Introduction

The **d**oc**s**pell **c**lient, short
[dsc](https://github.com/docspell/dsc), is a tool to use
docspell through the command line. It is also aims to be useful for
your own scripts and programs.

It is supposed to replace most of the shell scripts from the `tools/`
directory.

It is a work in progress; eventually most of the
[api](@/docs/api/_index.md) will be covered.

# Usage

Download the binary for your architecture from the [release
page](https://github.com/docspell/dsc/releases/latest) and rename it
to `dsc`. Then run `dsc help` to see an overview of all commands. The
help of each command is available via `dsc help [command]` or `dsc
[command] --help`.


There are docker images at
[dockerhub](https://hub.docker.com/repository/docker/docspell/dsc),
but it's usually easier to just download the binary. They should work
on most systems without additional setups.

Below are some quick infos to get started, please see [the project
page](https://github.com/docspell/dsc) for more info.


## Configuration

A configuration file can be used to have some predefined settings, for
example the docspell url, the admin secret etc. They can be overriden
by specifying them as options.

The config looks like this:

``` toml
docspell_url = "http://localhost:7880"
default_format = "Tabular"
admin_secret = "admin123"
default_account = "demo"
pdf_viewer = ["zathura", "{}"]
#pass_entry = "my/entry"
```

For linuxes, the default location is `~/.config/dsc/config.toml`. You
can give a config file explicitly via an option or the environment
variable `DSC_CONFIG`.

If you use the [pass](https://passwordstore.org) password manager, you
can add your password entry to the config file as well.

## Output format

The "output format" defines how the information is printed on screen.
The default output format is `Tabular` which prints a simple table.
This table can also be formatted as CSV using `csv` as output format.
These two modes are intended for humans and they may not present all
information available.

Alternatively, there is `json` and `lisp` as output format. These are
intended for machine consumption. They always contain all information.
If you look for some detail, use for example `json` to get all data in
a structured form. On the shell you can use the awesome tool
[jq](https://stedolan.github.io/jq/) to get exactly what you want.

## Login

Many tasks require to be logged in. This can be done via the `login`
subcommand. You can specify account and password or fallback to the
values in the config file.

Once logged in, the session token will be saved to the filesystem
(next to the config file) and is used for subsequent commands. It is
renewed if expiry is near. If you don't issue any commands for a while
you need to `login` again.

## Demo

<div class="columns is-centered is-full-width">
  <div class="column">
    <script id="asciicast-427679" src="https://asciinema.org/a/427679.js" async></script>
  </div>
</div>


# Use Cases / Examples

These are some examples. Each command has a good help explaining all
the options. Run `dsc [subcommand] --help` to see it.


## Uploads files

The `upload` subcommand can upload files to docspell. This is the
replacement for the `ds.sh` shell script.

You can specify a list of files that are all being uploaded. This
command doesn't require to be logged in, it can also upload via a
[source id](@/docs/webapp/uploading.md#anonymous-upload) or via the
[integration endpoint](@/docs/api/upload.md#integration-endpoint).

A source id can be given in the config file, then there are no
additional options required. The simplest form is this:

``` shell
❯ dsc upload *.pdf
File already in Docspell: article-velo.pdf
Adding to request: test-ocr.pdf
Sending request …
┌─────────┬──────────────────┐
│ success │ message          │
├─────────┼──────────────────┤
│ true    │ Files submitted. │
└─────────┴──────────────────┘
```

By default, duplicate files are detected and not uploaded. This
uploads all files in one single request. By default, each file results
in one item. Using `--single-item` all files can be put into one item.

It is possible to specify certain metadata, like tags or a folder,
that is then attached to the resulting item.


## Upload by traversing a directory

The above use case was about uploading files. Using the `upload`
subcommand with the `--traverse` option, you can traverse directories
and upload all files in them. In this mode, each file will be uploaded
in a separate request, so the `--single-item` option cannot be used.

There are options to exclude/include files based on a [glob
pattern](https://docs.rs/glob/0.3.0/glob/struct.Pattern.html).

``` shell
❯ dsc upload --traverse .
File already in Docspell: article-velo.pdf
File already in Docspell: demo/dirc/scan.21-03-12.15-50-54.pdf
File already in Docspell: demo/dirc/test-stamp.pdf
File already in Docspell: demo/letter-de.pdf
Uploading eike/keywords.pdf
File already in Docspell: eike/large-file.pdf
Uploading eike/letter-en.pdf
File already in Docspell: test-ocr.pdf
┌─────────┬────────────┐
│ success │ message    │
├─────────┼────────────┤
│ true    │ Uploaded 2 │
└─────────┴────────────┘
```

The `--poll` option allows to periodically traverse and upload
directories.


## Watch a directory

The `watch` subcommand can be used to watch one or more directories
and upload files when they arrive. It uses the `upload` command under
the hood and therefore most options are also available here. You can
upload via a source url, the integration endpoint or a valid session
(requires to login).

It detects file creations and skips a rename within a watched folder.
The flag `-r` or `--recursive` is required to recursively watch a
directory.

``` shell
❯ dsc watch -r .
Watching directory (Recursive): .
Press Ctrl-C to quit.
------------------------------------------------------------------------------
Got: /home/eike/workspace/projects/dsc/local/files/./demo/letter-de.pdf
Adding to request: /home/eike/workspace/projects/dsc/local/files/./demo/letter-de.pdf
Sending request …
Server: Files submitted.
```

The `--matches` option allows to define a pattern for files to include.

If watching a directory is not possible due to system constraints
(e.g. when using NFS or SAMBA shares), a less efficient option is to
use the `upload` subcommand with `--poll` option which periodically
traverses a directory.

When using the integration endpoint, it requires to specify `-i` and
potentially a secret if the endpoint is protected with a secret.


## Download files

The `download` command allows to download files that match a given
query. It is possible to download them all flat into some directory or
directly into a zip file. For example, download all files that are
tagged with `todo` into a zip file:

``` shell
❯ dsc download --zip 'tag:todo'
Zipping 2 attachments into docspell-files.zip
Downloading DOC-20191223-155707.jpg.pdf …
Downloading DOC-20200803-174448.jpg.pdf …
```

It downloads the converted PDF files by default, which can be changed
via some options.

``` shell
❯ dsc download --zip --original 'tag:todo'
Zipping original files of 2 attachments into docspell-files.zip
Downloading DOC-20191223-155707.jpg …
Downloading DOC-20200803-174448.jpg …
```


## Export data

The `export` command allows to download all items with metadata and
their files. It downloads all items by default, but a query is also
supported.

In contrast to the `download` command, this is intended for getting
everything out of docspell in some independent format. Files are
downloaded (only original files) and the items metadata is also
stored. So you don't loose the tags and correspondents that are
carefully maintained with each item.

It expects one directory where it will create a specfific directory
structure as follows:

```
exports/
├── by_date
│   ├── 2019-07
│   ├── 2020-08
|       ├── BV2po65mAFU-…-bqUiwjz8f2W -> ../../items/BV/BV2po65mAFU-…-bqUiwjz8f2W
|       └── FTUnhZ3AE1H-…-RQ9KhtRi486 -> ../../items/FT/FTUnhZ3AE1H-…-RQ9KhtRi486
│   ├── …
│   └── 2021-07
├── by_tag
│   ├── Contract
│   ├── Important
│   ├── Invoice
|   │   ├── 455h3cQNdna-…-t6dF7NjAuDm -> ../../items/45/455h3cQNdna-…-t6dF7NjAuDm
|   │   ├── 5yQ95tQ4khY-…-S9KrxcbRkZR -> ../../items/5y/5yQ95tQ4khY-…-S9KrxcbRkZR
|   │   ├── 7xoiE4XdwgD-…-Eb2S3BCSd38 -> ../../items/7x/7xoiE4XdwgD-…-Eb2S3BCSd38
|   │   └── 93npVoA73Cx-…-BnxYNsf4Qvi -> ../../items/93/93npVoA73Cx-…-BnxYNsf4Qvi
│   ├── …
│   └── Todo
└── items
    ├── 45
    |   └── 455h3cQNdna-w8oTEw9wtpE-G7bCJbVpZPw-t6dF7NjAuDm
    |       ├── files
    |       │   └── DOC-20200803-174448.jpg
    |       └── metadata.json
    ├── …
    └── Hb
```

All your items are stored below the `items` directory. It contains
subdirectories that are created from the first two characters of the
item id. Inside this folder, a folder with the complete item id is
created and there all the data to the item is stored: the metadata in
`metadata.json` and all files below `files/`.

The options `--date-links` and `--tag-links` create the other two
folders: `by_tag` and `by_date`. In there you'll find symlinks into
the `items` folder that are organized by some metadata, namely tag and
the item date.

Example run:
``` shell
❯ dsc export --all --date-links --tag-links --target exports
Exported item: test3.zip
Exported item: README.md
Exported item: LICENSE.txt
Exported item: TestRMarkdown.pdf
Exported item: DOC-20191223-155729.jpg
Exported item: DOC-20191223-155707.jpg
Exported item: DOC-20200808-154204.jpg
Exported item: DOC-20200807-115654.jpg
Exported item: DOC-20200803-174448.jpg
Exported item: DOC-20200803-174448.jpg
Exported item: DOC-20200803-174448.jpg
Exported item: DOC-20200803-174448.jpg
Exported item: DOC-20200804-132305.jpg
Exported item: DOC-20191223-155707.jpg
Exported item: keyweb.eml
Exported 15 items.
```

With output format `json` or `lisp` each item is printed instead in
full detail.

## Admin commands

These are a set of commands that simply call a route at the server to
submit a maintenance task or to reset the password of some user. These
commands require the [admin
secret](@/docs/configure/_index.md#admin-endpoint) either in the
config file or as an argument.

### Reset user password

``` shell
❯ dsc admin reset-password --account demo
┌─────────┬──────────────┬──────────────────┐
│ success │ new password │ message          │
├─────────┼──────────────┼──────────────────┤
│ true    │ 2q2UeCVvMYg  │ Password updated │
└─────────┴──────────────┴──────────────────┘
```

### Recreate fulltext index

``` shell
❯ dsc admin --admin-secret admin123 recreate-index
┌─────────┬─────────────────────────────────────┐
│ success │ message                             │
├─────────┼─────────────────────────────────────┤
│ true    │ Full-text index will be re-created. │
└─────────┴─────────────────────────────────────┘
```

### Convert all files to PDF
``` shell
❯ dsc admin --admin-secret admin123 convert-all-pdf
┌─────────┬─────────────────────────────────┐
│ success │ message                         │
├─────────┼─────────────────────────────────┤
│ true    │ Convert all PDFs task submitted │
└─────────┴─────────────────────────────────┘
```

This may be necessary if you disabled pdf conversion before and are
enabling it now.

### Regenerate preview images

``` shell
❯ dsc admin --admin-secret admin123 convert-all-pdf
┌─────────┬───────────────────────────────────────┐
│ success │ message                               │
├─────────┼───────────────────────────────────────┤
│ true    │ Generate all previews task submitted. │
└─────────┴───────────────────────────────────────┘
```

This submits tasks to (re)generate preview images of all files. This
is necessary if you changed the `preview.dpi` setting in joex'
config.

## Search for items

The `search` command takes a [query](@/docs/query/_index.md) and
prints the results.

``` shell
❯ dsc search 'corr:*'
┌──────────┬────────────────────────────┬───────────┬────────────┬─────┬───────────────────────────┬───────────────┬────────┬─────────────┬────────────┬───────┐
│ id       │ name                       │ state     │ date       │ due │ correspondent             │ concerning    │ folder │ tags        │ fields     │ files │
├──────────┼────────────────────────────┼───────────┼────────────┼─────┼───────────────────────────┼───────────────┼────────┼─────────────┼────────────┼───────┤
│ HVK7JuCF │ test-ocr.pdf               │ created   │ 2021-07-18 │     │ Pancake Company           │               │        │ Certificate │            │ 1     │
│ 3odNawKE │ letter-en.pdf              │ confirmed │ 2021-07-18 │     │ Pancake Company           │               │        │ invoice     │            │ 1     │
│ 3MA5NdhS │ large-file.pdf             │ confirmed │ 2021-07-18 │     │ Axa                       │               │        │ Certificate │            │ 1     │
│ HDumXkRm │ keywords.pdf               │ confirmed │ 2021-07-18 │     │ Pancake Company           │               │        │ invoice     │            │ 1     │
│ 733gM656 │ test-stamp.pdf             │ created   │ 2021-07-18 │     │ Pancake Company           │               │        │ Contract    │            │ 1     │
│ 8LiciitB │ scan.21-03-12.15-50-54.pdf │ confirmed │ 2021-07-18 │     │ Supermarket               │               │        │ Receipt     │ CHF 89.44  │ 1     │
│ 8nFt2z7T │ article-velo.pdf           │ confirmed │ 2021-07-18 │     │ Supermarket/Rudolf Müller │ Rudolf Müller │        │ invoice     │ CHF 123.11 │ 1     │
│ kfugGdXU │ letter-de.pdf              │ created   │ 2021-07-18 │     │ Axa                       │ Rudolf Müller │        │ invoice     │            │ 1     │
└──────────┴────────────────────────────┴───────────┴────────────┴─────┴───────────────────────────┴───────────────┴────────┴─────────────┴────────────┴───────┘
```

The same can be formatted as json and, for example, only print the ids:
``` shell
❯ dsc -f json search 'corr:*' | jq '.groups[].items[].id'
"HVK7JuCFt4W-qxkcwq1cWCV-dvpGo4DpZzU-Q16Xoujojas"
"3odNawKE1Ek-YJrWfPzekAq-47cjt14sexd-GK35JAEAanx"
"3MA5NdhSrbx-3JkjEpqHiyU-XyVNb15tioh-SUVjMLi1aoV"
"HDumXkRmDea-dNryjtRjk3V-ysdJmJNQGQS-UFb4DWNZJ3F"
"733gM656S4T-d4HmEgdAV6Z-9zuHAd3biKM-mBwNriZpqMB"
"8LiciitBVTi-DTmgiEUdqAJ-xXPckMvFHMc-JSiJMYvLaWh"
"8nFt2z7T9go-1qaCTTgodub-592n6gpmdNR-VRcyYAyT7qj"
"kfugGdXUGUc-mReaUnJxyUL-R44Lf7yH6RK-2JbZ1bv7dw"
```


# Docker

The provided docker-compose setup runs this script to watch a single
directory, `./docs` in current directory, for new files. If a new file
is detected, it is pushed to docspell.

This utilizes the [integration
endpoint](@/docs/api/upload.md#integration-endpoint), which is enabled
in the config file, to allow uploading documents for all collectives.
A subfolder must be created for each registered collective. The docker
containers are configured to use http-header protection for the
integration endpoint. This requires you to provide a secret, that is
shared between the rest-server and the `dsc` tool. This can be done by
defining an environment variable which gets picked up by the
containers defined in `docker-compose.yml`:

``` bash
export DOCSPELL_HEADER_VALUE="my-secret"
docker-compose up
```


Now you can create a folder `./docs/<collective-name>` and place all
files in there that you want to import. Once dropped in this folder
the `consumedir` container will push it to docspell.
