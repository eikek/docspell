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

## Memory Usage

The memory requirements for the joex component depends on the document
language and the configuration for [file
processing](@/docs/configure/_index.md#file-processing). The
`nlp.mode` setting has significant impact, especially when your
documents are in German. Here are some rough numbers on jvm heap usage
(the same small jpeg file was used for all tries):

<table class="table is-hoverable is-striped">
<thead>
  <tr><th>nlp.mode</th><th>English</th><th>German</th><th>French</th></tr>
</thead>
<tfoot>
</tfoot>
<tbody>
  <tr><td>full</td><td>420M</td><td>950M</td><td>490M</td></tr>
  <tr><td>basic</td><td>170M</td><td>380M</td><td>390M</td></tr>
</tbody>
</table>

When using `mode=full`, a heap setting of at least `-Xmx1400M` is
recommended. For `mode=basic` a heap setting of at least `-Xmx500M` is
recommended.

Other languages can't use these two modes, and so don't require this
amount of memory (but don't have as good results). Then you can go
with less heap.

More details about these modes can be found
[here](@/docs/joex/file-processing.md#text-analysis).


The restserver component is very lightweight, here you can use
defaults.


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

It is recommended to run joex with the G1GC enabled. If you use java8,
you need to add an option to use G1GC (`-XX:+UseG1GC`), for java11
this is not necessary (but doesn't hurt either). This could look like
this:

```
./docspell-joex-{{version()}}/bin/docspell-joex -J-Xmx1596M -J-XX:+UseG1GC -- /path/to/joex.conf
```
