# Webextension for Docspell

The idea is to click on a file in firefox and send it to docspell. It
is downloaded in the context of your current page. Then handed to an
application that pushes it to docspell. There is a browser add-on
implementing this in `tools/webextension`. This add-on only works with
firefox.

Note: the same can be achieved by running the `dsc watch` on some
directory and let the browser (and other programs) download files in
this directory.

----

Installation is a bit complicated, since you need to install external
tools and the web extension. Both work together.

# Build it

In the source root, run `sbt make-tools`. After it completes, there is
a zip file in the `tools/target` folder. Inside this zip, you can find
the web extension.

# Install `dsc`

First copy the [dsc](@/docs/tools/cli.md) tool somewhere in your
`PATH`, maybe `/usr/local/bin`.


# Install the native part

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
[here](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests#manifest_location)
for details.

And you might want to modify this json file, so the path to the
`native.py` script is correct (it must be absolute).

If the `dsc` tool is in your `$PATH`, then this should work. You need
to provide a default source id in your `~/.config/dsc/config.toml` so
that the upload command can be used without further arguments.

Otherwise, edit the `native.py` script and change the path to the tool
and/or the arguments. Or create a file
`$HOME/.config/docspell/dsc.cmd` whose content is the path to the
`dsc` tool.


# Install the extension

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
script. This script will in turn call `dsc` which finally uploads it
to your configured URLs.

Open the Add-ons page (`Ctrl`+`Shift`+`A`), the new add-on should be
there.
