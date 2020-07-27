+++
title = "Running"
weight = 30
+++

# Running

Run the start script (in the corresponding `bin/` directory when using
the zip files):

```
$ ./docspell-restserver*/bin/docspell-restserver
$ ./docspell-joex*/bin/docspell-joex
```

This will startup both components using the default configuration. The
configuration should be adopted to your needs. For example, the
database connection is configured to use a H2 database in the `/tmp`
directory. Please refer to the [configuration
page](@/docs/configure/_index.md) for how to create a custom config
file. Once you have your config file, simply pass it as argument to
the command:

```
$ ./docspell-restserver*/bin/docspell-restserver /path/to/server-config.conf
$ ./docspell-joex*/bin/docspell-joex /path/to/joex-config.conf
```

After starting the rest server, you can reach the web application at
path `/app`, so using default values it would be
`http://localhost:7880/app`. There also is a redirect from `/` to
`/app`.

You should be able to create a new account and sign in. Check the
[configuration page](@/docs/configure/_index.md) to further customize
docspell.


## Options

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
