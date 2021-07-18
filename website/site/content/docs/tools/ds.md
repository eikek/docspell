+++
title = "Upload CLI (⊗)"
description = "A script to quickly upload files from the command line."
weight = 100
+++


{% infobubble(mode="info", title="⚠ Please note") %}
This script is now obsolete, you can use the [**CLI tool**](../cli/) instead.

Use the `upload` command (or the `up` alias), like `dsc up *.pdf`.
{% end %}

# Introduction

The `tools/ds.sh` is a bash script to quickly upload files from the
command line. It reads a configuration file containing the URLs to
upload to. Then each file given to the script will be uploaded to al
URLs in the config.

The config file is expected in
`$XDG_CONFIG_HOME/docspell/ds.conf`. `$XDG_CONFIG_HOME` defaults to
`~/.config`.

The config file contains lines with key-value pairs, separated by a
`=` sign. Lines starting with `#` are ignored. Example:

```
# Config file
url.1 = http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
url.2 = http://localhost:7880/api/v1/open/upload/item/6DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The key must start with `url`. The urls should be [anonymous upload
urls](@/docs/webapp/uploading.md#anonymous-upload).


# Usage

- The `-c` option allows to specifiy a different config file.
- The `-h` option shows a help overview.
- The `-d` option deletes files after upload was successful
- The `-e` option can be used to check for file existence in docspell.
  Instead of uploading, the script only checks whether the file is in
  docspell or not.

The script takes a list of files as arguments.


Example:

``` bash
./ds.sh ~/Downloads/*.pdf
```
