---
layout: docs
title: Tools
---

# {{ page.title }}

The `tools/` folder contains some scripts and other resources intented
for integrating docspell.

## consumedir

The `consumerdir.sh` is a bash script that works in two modes:

- Go through all files in given directories (non recursively) and sent
  each to docspell.
- Watch one or more directories for new files and upload them to
  docspell.

It can watch or go through one or more directories. Files can be
uploaded to multiple urls.

Run the script with the `-h` option, to see a short help text. The
help text will also show the values for any given option.

The script requires `curl` for uploading. It requires the
`inotifywait` command if directories should be watched for new
files. If the `-m` option is used, the script will skip duplicate
files. For this the `sha256sum` command is required.

Example for watching two directories:

``` bash
./tools/consumedir.sh --path ~/Downloads --path ~/pdfs -m /var/run/consumedir -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The script by default watches the given directories. If the `-o`
option is used, it will instead go through these directories and
upload all pdf files in there.

Example for uploading all immediatly (the same as above only with `-o`
added):

``` bash
./tools/consumedir.sh -o --path ~/Downloads --path ~/pdfs/ -m /var/run/consumedir -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```


### Systemd

The script can be used with systemd to run as a service. This is an
example unit file:

```
[Unit]
After=networking.target
Description=Docspell Consumedir

[Service]
Environment="PATH=/set/a/path"

ExecStartPre=mkdir -p /var/run/consumedir && chown -R someuser /var/run/consumedir
ExecStart=/bin/su -s /bin/bash someuser -c "consumedir.sh --path '/a/path/' -m '/var/run/consumedir' 'http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ'"
```

This unit file is just an example, it needs some fiddling. It assumes
an existing user `someuser` that is used to run this service. The url
`http://localhost:7880/api/v1/open/upload/...` is an anonymous upload
url as described [here](./uploading.html).


## ds.sh

A bash script to quickly upload files from the command line. It reads
a configuration file containing the URLs to upload to. Then each file
given to the script will be uploaded to al URLs in the config.

The config file is expected in
`$XDG_CONFIG_HOME/docspell/ds.conf`. `$XDG_CONFIG_HOME` defaults to
`~/.config`.

The config file contains lines with key-value pairs, separated by an
`=` sign. Lines starting with `#` are ignored. Example:

```
# Config file
url.1 = http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
url.2 = http://localhost:7880/api/v1/open/upload/item/6DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The key must start with `url`.

### Usage

The `-h` option shows a help overview.

The script takes a list of files as arguments. It checks the file
types and will raise an error (and quit) if a file is included that is
not a PDF. The `-s` option can be used to skip them instead.

The `-c` option allows to specifiy a different config file.

Example:

``` bash
./ds.sh ~/Downloads/*.pdf
```
