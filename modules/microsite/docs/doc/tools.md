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
./tools/consumedir.sh --path ~/Downloads --path ~/pdfs -m -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The script by default watches the given directories. If the `-o`
option is used, it will instead go through these directories and
upload all pdf files in there.

Example for uploading all immediatly (the same as above only with `-o`
added):

``` bash
./tools/consumedir.sh -o --path ~/Downloads --path ~/pdfs/ -m -dv http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
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

ExecStart=/bin/su -s /bin/bash someuser -c "consumedir.sh --path '/a/path/' -m 'http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ'"
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

The config file contains lines with key-value pairs, separated by a
`=` sign. Lines starting with `#` are ignored. Example:

```
# Config file
url.1 = http://localhost:7880/api/v1/open/upload/item/5DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
url.2 = http://localhost:7880/api/v1/open/upload/item/6DxhjkvWf9S-CkWqF3Kr892-WgoCspFWDo7-XBykwCyAUxQ
```

The key must start with `url`. The urls should be [anonymous upload
urls](./uploading.html).


### Usage

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


## Webextension for Docspell

Idea: Inside the browser click on a PDF and send it to docspell. It is
downloaded in the context of your current page. Then handed to an
application that pushes it to docspell. There is a browser add-on
implementing this in `tools/webextension`. This add-on only works with
firefox.

### Install

This is a bit complicated, since you need to install external tools
and the web extension. Both work together.

#### Install `ds.sh`

First copy the `ds.sh` tool somewhere in your `PATH`, maybe
`/usr/local/bin` as described above.


#### Install the native part

Then install the "native" part of the web extension:

Copy or symlink the `native.py` script into some known location. For
example:

``` bash
ln -s ~/docspell-checkout/tools/webextension/native/native.py /usr/local/share/docspell/native.py
```

Then copy the `app_manifest.json` to
`$HOME/.mozilla/native-messaging-hosts/docspell.json`. For example:

``` bash
cp ~/docspell-checkout/tools/webextension/native/app_manifest.json  ~/.mozilla/native-messaging-hosts/docspell.json
```

See
[here](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests#Manifest_location)
for details.

And you might want to modify this json file, so the path to the
`native.py` script is correct (it must be absolute).

If the `ds.sh` script is in your `$PATH`, then this should
work. Otherwise, edit the `native.py` script and change the path to
the tool. Or create a file `$HOME/.config/docspell/ds.cmd` whose
content is the path to the `ds.sh` script.


#### Install the extension

An extension file can be build using the `make-xpi.sh` script. But
installing it in "standard" firefox won't work, because [Mozilla
requires extensions to be signed by
them](https://wiki.mozilla.org/Add-ons/Extension_Signing). This means
creating an account and going through some process…. So here are two
alternatives:

1. Open firefox and type `about:debugging` in the addressbar. Then
   click on *'Load Temporary Add-on...'* and select the
   `manifest.json` file. The extension is now installed. The downside
   is, that the extension will be removed once firefox is closed.
2. Use Firefox ESR, which allows to install Add-ons not signed by
   Mozilla. But it has to be configured: Open firefox and type
   `about:config` in the address bar. Search for key
   `xpinstall.signatures.required` and set it to `false`. This is
   described on the last paragraph on [this
   page](https://support.mozilla.org/en-US/kb/add-on-signing-in-firefox).

When you right click on a file link, there should be a context menu
entry *'Docspell Upload Helper'*. The add-on will download this file
using the browser and then send the file path to the `native.py`
script. This script will in turn call `ds.sh` which finally uploads it
to your configured URLs.

Open the Add-ons page (`Ctrl`+`Shift`+`A`), the new add-on should be
there.
