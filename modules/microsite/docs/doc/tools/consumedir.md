---
layout: docs
title: Consume Directory
permalink: doc/tools/consumedir
---

# {{ page.title }}

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
./tools/consumedir.sh --path ~/Downloads --path ~/pdfs -m -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The script by default watches the given directories. If the `-o`
option is used, it will instead go through these directories and
upload all files in there.

Example for uploading all immediatly (the same as above only with `-o`
added):

``` bash
./tools/consumedir.sh -o --path ~/Downloads --path ~/pdfs/ -m -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```


## Systemd

The script can be used with systemd to run as a service. This is an
example unit file:

```
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
url as described [here](../uploading#anonymous-upload).


## Docker

The provided docker image runs this script to watch a directory for
new files. If a new file is detected, it is pushed to docspell.

For this to work, the container must know about a valid upload url.
Therefore, you must first signup and create such an upload url, as
described [here](doc/uploading#anonymous-upload). Get only the id
(something like `AvR6sA8GKFm-hgYDgZfwzXa-Tqnu8yqyz6X-KzuefvEvrRf`) and
define an environment variable `SOURCE_ID` with that value before
running `docker-compose up` a second time.

```
export SOURCE_ID="AvR6sA8GKFm-hgYDgZfwzXa-Tqnu8yqyz6X-KzuefvEvrRf"
docker-compose up
```

Now you can create a folder `./docs` and place all files in there that
you want to import. Once dropped in this folder the `consumedir`
container will push it to docspell.
