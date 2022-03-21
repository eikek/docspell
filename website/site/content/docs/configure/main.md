+++
title = "Main"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 10
template = "docs.html"
+++

# Configuration

Docspell's executables (restserver and joex) can take one argument – a
configuration file. If that is not given, the defaults are used,
overriden by environment variables. A config file overrides default
values, so only values that differ from the defaults are necessary.
The complete default options and their documentation is at the end of
this page.

Besides the config file, another way is to provide individual settings
via key-value pairs to the executable by the `-D` option. For example
to override only `base-url` you could add the argument
`-Ddocspell.server.base-url=…` to the command. Multiple options are
possible. For more than few values this is very tedious, obviously, so
the recommended way is to maintain a config file. If these options
*and* a file is provded, then any setting given via the `-D…` option
overrides the same setting from the config file.

At last, it is possible to configure docspell via environment
variables if there is no config file supplied (if a config file *is*
supplied, it is always preferred). Note that this approach is limited,
as arrays are not supported. A list of environment variables can be
found at the [end of this page](#environment-variables). The
environment variable name follows the corresponding config key - where
dots are replaced by underscores and dashes are replaced by two
underscores. For example, the config key `docspell.server.app-name`
can be defined as env variable `DOCSPELL_SERVER_APP__NAME`.

It is also possible to specify environment variables inside a config
file (to get a mix of both) - please see the [documentation of the
config library](https://github.com/lightbend/config#standard-behavior)
for more on this.

# File Format

The format of the configuration files can be
[HOCON](https://github.com/lightbend/config/blob/master/HOCON.md#hocon-human-optimized-config-object-notation),
JSON or what this [config
library](https://github.com/lightbend/config) understands. The default
values below are in HOCON format, which is recommended, since it
allows comments and has some [advanced
features](https://github.com/lightbend/config#features-of-hocon).
Please also see their documentation for more details.

A short description (please check the links for better understanding):
The config consists of key-value pairs and can be written in a
JSON-like format (called HOCON). Keys are organized in trees, and a
key defines a full path into the tree. There are two ways:

```
a.b.c.d=15
```

or

```
a {
  b {
    c {
      d = 15
    }
  }
}
```

Both are exactly the same and these forms are both used at the same
time. Usually the braces approach is used to group some more settings,
for better readability.

Strings that contain "not-so-common" characters should be enclosed in
quotes. It is possible to define values at the top of the file and
reuse them on different locations via the `${full.path.to.key}`
syntax. When using these variables, they *must not* be enclosed in
quotes.


# Config Options

The configuration of both components uses separate namespaces. The
configuration for the REST server is below `docspell.server`, while
the one for joex is below `docspell.joex`.

You can therefore use two separate config files or one single file
containing both namespaces.

## App-id

The `app-id` is the identifier of the corresponding instance. It *must
be unique* for all instances. By default the REST server uses `rest1`
and joex `joex1`. It is recommended to overwrite this setting to have
an explicit and stable identifier should multiple instances are
intended.

``` bash
docspell.server.app-id = "rest1"
docspell.joex.app-id = "joex1"
```

## Other options

Please see the menu on the left for details about specific
configuration options.

# JVM Options

The start scripts support some options to configure the JVM. One often
used setting is the maximum heap size of the JVM. By default, java
determines it based on properties of the current machine. You can
specify it by given java startup options to the command:

```
$ ./docspell-restserver*/bin/docspell-restserver -J-Xmx1G -- /path/to/server-config.conf
```

This would limit the maximum heap to 1GB. The double slash separates
internal options and the arguments to the program. Another frequently
used option is to change the default temp directory. Usually it is
`/tmp`, but it may be desired to have a dedicated temp directory,
which can be configured:

```
$ ./docspell-restserver*/bin/docspell-restserver -J-Xmx1G -Djava.io.tmpdir=/path/to/othertemp -- /path/to/server-config.conf
```

The command:

```
$ ./docspell-restserver*/bin/docspell-restserver -h
```

gives an overview of supported options.

It is recommended to run joex with the G1GC enabled. If you use java8,
you need to add an option to use G1GC (`-XX:+UseG1GC`), for java11
this is not necessary (but doesn't hurt either). This could look like
this:

```
./docspell-joex-{{version()}}/bin/docspell-joex -J-Xmx1596M -J-XX:+UseG1GC -- /path/to/joex.conf
```

Using these options you can define how much memory the JVM process is
able to use. This might be necessary to adopt depending on the usage
scenario and configured text analysis features.

Please have a look at the corresponding
[section](@/docs/configure/file-processing.md#memory-usage).



# Logging

By default, docspell logs to stdout. This works well, when managed by
systemd or other inits. Logging can be configured in the configuration
file or via environment variables. There are only two settings:

- `minimum-level` specifies the log level to control the verbosity.
  Levels are ordered from: *Trace*, *Debug*, *Info*, *Warn* and
  *Error*
- `format` this defines how the logs are formatted. There are two
  formats for humans: *Plain* and *Fancy*. And two more suited for
  machine consumption: *Json* and *Logfmt*. The *Json* format contains
  all details, while the others may omit some for readability

These settings are the same for joex and the restserver component.

# Default Config
## Rest Server

{{ incl_conf(path="templates/shortcodes/server.conf") }}


## Joex


{{ incl_conf(path="templates/shortcodes/joex.conf") }}

## Environment Variables

Environment variables can be used when there is no config file
supplied. The listing below shows all possible variables and their
default values.

{{ incl_conf(path="templates/shortcodes/config.env.txt") }}
