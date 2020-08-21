+++
title = "Consume Directory"
description = "A script to watch a directory for new files and upload them to docspell."
weight = 30
+++

# Introduction

The `consumerdir.sh` is a bash script that works in two modes:

- Go through all files in given directories (recursively, if `-r` is
  specified) and sent each to docspell.
- Watch one or more directories for new files and upload them to
  docspell.

It can watch or go through one or more directories. Files can be
uploaded to multiple urls.

Run the script with the `-h` or `--help` option, to see a short help
text. The help text will also show the values for any given option.

The script requires `curl` for uploading. It requires the
`inotifywait` command if directories should be watched for new
files.

Example for watching two directories:

``` bash
./tools/consumedir.sh --path ~/Downloads --path ~/pdfs -m -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The script by default watches the given directories. If the `-o` or
`--once` option is used, it will instead go through these directories
and upload all files in there.

Example for uploading all immediatly (the same as above only with `-o`
added):

``` bash
$ consumedir.sh -o --path ~/Downloads --path ~/pdfs/ -m -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```


The URL can be any docspell url that accepts uploads without
authentication. This is usually a [source
url](@/docs/webapp/uploading.md#anonymous-upload). It is also possible
to use the script with the [integration
endpoint](@/docs/webapp/uploading.md#integration-endpoint).


## Integration Endpoint

When given the `-i` or `--integration` option, the script changes its
behaviour slightly to work with the [integration
endpoint](@/docs/webapp/uploading.md#integration-endpoint).

First, if `-i` is given, it implies `-r` – so the directories are
watched or traversed recursively. The script then assumes that there
is a subfolder with the collective name. Files must not be placed
directly into a folder given by `-p`, but below a sub-directory that
matches a collective name. In order to know for which collective the
file is, the script uses the first subfolder.

If the endpoint is protected, the credentials can be specified as
arguments `--iuser` and `--iheader`, respectively. The format is for
both `<name>:<value>`, so the username cannot contain a colon
character (but the password can).

Example:
``` bash
$ consumedir.sh -i -iheader 'Docspell-Integration:test123' -m -p ~/Downloads/ http://localhost:7880/api/v1/open/integration/item
```

The url is the integration endpoint url without the collective, as
this is amended by the script.

This watches the folder `~/Downloads`. If a file is placed in this
folder directly, say `~/Downloads/test.pdf` the upload will fail,
because the collective cannot be determined. Create a subfolder below
`~/Downloads` with the name of a collective, for example
`~/Downloads/family` and place files somewhere below this `family`
subfolder, like `~/Downloads/family/test.pdf`.


## Duplicates

With the `-m` option, the script will not upload files that already
exist at docspell. For this the `sha256sum` command is required.

So you can move and rename files in those folders without worring
about duplicates. This allows to keep your files organized using the
file-system and have them mirrored into docspell as well.


# Systemd

The script can be used with systemd to run as a service. This is an
example unit file:

``` systemd
[Unit]
After=networking.target
Description=Docspell Consumedir

[Service]
Environment="PATH=/set/a/path"

ExecStart=/bin/su -s /bin/bash someuser -c "consumedir.sh --path '/a/path/' -m 'http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ'"
```

This unit file is just an example, it needs some fiddling. It assumes
an existing user `someuser` that is used to run this service. The url
`http://localhost:7880/api/v1/open/upload/...` is an anonymous upload
url as described [here](@/docs/webapp/uploading.md#anonymous-upload).


# Docker

The provided docker image runs this script to watch a single
directory, `./docs` in current directory, for new files. If a new file
is detected, it is pushed to docspell.

This utilizes the [integration
endpoint](@/docs/webapp/uploading.md#integration-endpoint), which is
enabled in the config file, to allow uploading documents for all
collectives. A subfolder must be created for each registered
collective. The docker containers are configured to use http-header
protection for the integration endpoint. This requires you to provide
a secret, that is shared between the rest-server and the
`consumedir.sh` script. This can be done by defining an environment
variable which gets picked up by the containers defined in
`docker-compose.yml`:

``` bash
export DOCSPELL_HEADER_VALUE="my-secret"
docker-compose up
```


Now you can create a folder `./docs/<collective-name>` and place all
files in there that you want to import. Once dropped in this folder
the `consumedir` container will push it to docspell.
