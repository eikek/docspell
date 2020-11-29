+++
title = "Export Files"
description = "Downloads all files from docspell."
weight = 65
+++

# export-files.sh

This script can be used to download all files from docspell that have
been uploaded before.

# Requirements

It is a bash script that additionally needs
[curl](https://curl.haxx.se/) and
[jq](https://stedolan.github.io/jq/).

# Usage

```
./export-files.sh <docspell-base-url> <target-directory>
```

For example, if docspell is at `http://localhost:7880`:

```
./export-files.sh http://localhost:7880 /tmp/ds-downloads
```

The script asks for your account name and password. It then logs in
and goes through all items downloading the metadata as json and the
attachments. It will fetch the original files (not the converted
ones).
