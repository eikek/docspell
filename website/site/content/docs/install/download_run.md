+++
title = "Manual Installation"
weight = 22
+++

# Download and Run

You can install via zip or deb archives. Please see the
[prerequisites](@/docs/install/prereq.md) first.

## Using zip files

1. Download the two files:
   - <a href="https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-restserver-{{version()}}.zip">docspell-restserver-{{version()}}.zip</a>
   - <a href="https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-joex-{{version()}}.zip">docspell-joex-{{version()}}.zip</a>
2. Unzip both files:
   ``` bash
   $ unzip docspell-*.zip
   ```
3. Open two terminal windows and navigate to the the directory
   containing the zip files.
4. Start both components executing:
   ``` bash
   $ ./docspell-restserver*/bin/docspell-restserver
   ```
   in one terminal and
   ``` bash
   $ ./docspell-joex*/bin/docspell-joex
   ```
   in the other.
5. Point your browser to: <http://localhost:7880/app>
6. Register a new account, sign in and try it.

Note, that this setup doesn't include watching a directory nor
fulltext search. Using zip/deb files requires to take care of the
[prerequisites](@/docs/install/prereq.md) yourself.

The provided scripts in
[docspell-tools-{{version()}}.zip](https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-tools-{{version()}}.zip)
must be extracted and installed manually somewhere in your `$PATH`.

## Using deb files

Please checkout this comprehensive
[guide](https://github.com/andreklug/docspell-debian) for installing
on a Debian system.

Packages are also provided at the release page:

- <a href="https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-restserver_{{version()}}_all.deb">docspell-restserver_{{version()}}_all.deb</a>
- <a href="https://github.com/eikek/docspell/releases/download/v{{version()}}/docspell-joex_{{version()}}_all.deb">docspell-joex_{{version()}}_all.deb</a>

The DEB packages can be installed on Debian, or Debian based Distros:

``` bash
$ sudo dpkg -i docspell*.deb
```

Then the start scripts are in your `$PATH`. Run `docspell-restserver`
or `docspell-joex` from a terminal window.

The packages come with a systemd unit file that will be installed to
autostart the services.


# Running

Run the start script (in the corresponding `bin/` directory when using
the zip files):

```
$ ./docspell-restserver*/bin/docspell-restserver
$ ./docspell-joex*/bin/docspell-joex
```

This will startup both components using the default configuration.
Please refer to the [configuration
page](@/docs/configure/main.md) for how to create a custom
config file. Once you have your config file, simply pass it as
argument to the command:

```
$ ./docspell-restserver*/bin/docspell-restserver /path/to/server-config.conf
$ ./docspell-joex*/bin/docspell-joex /path/to/joex-config.conf
```

After starting the rest server, you can reach the web application
`http://localhost:7880/`.

You should be able to create a new account and sign in. When creating
a new account, use the same name for collective and user and then
login with this name.

## Upgrading

Since [downgrading](@/docs/install/downgrading.md) is not supported,
it is recommended to backup your database before upgrading. Should
something not work as expected, restore the database backup and go
back to the previous version.

When using the zip or deb files, either install the new deb files via
your package manager or download and unpack the new zip files. You
might want to have a look at the changelog, since it is sometimes
necessary to modify the config file.

## More

### Fulltext Search

Fulltext search is powered by [SOLR](https://solr.apache.org). You
need to install solr and create a core for docspell. Then cange the
solr url for both components (restserver and joex) accordingly. See
the relevant section in the [config
page](@/docs/configure/fulltext-search.md).


### Watching a directory

The [dsc](@/docs/tools/cli.md) tool with the `watch` subcommand can be
used for this. Using systemd or something similar, it is possible to
create a system service that runs the script in "watch mode".
