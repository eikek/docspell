---
layout: docs
title: Installation
permalink: doc/install
---

# {{ page.title }}

This page contains detailed installation instructions. For a quick
start, refer to [this page](../getit).

Docspell has been developed and tested on a GNU/Linux system. It may
run on Windows and MacOS machines, too (ghostscript and tesseract are
available on these systems). But I've never tried.

Docspell consists of two components that are started in separate
processes:

1. *REST Server* This is the main application, providing the REST Api
   and the web application.
2. *Joex* (job executor) This is the component that does the document
   processing.

They can run on multiple machines. All REST server and Joex instances
should be on the same network. It is not strictly required that they
can reach each other, but the components can then notify themselves
about new or done work.

While this is possible, the simple setup is to start both components
once on the same machine.

The [download page](https://github.com/eikek/docspell/releases)
provides pre-compiled packages and the [development page](../dev)
contains build instructions.


## Prerequisites

The two components have one prerequisite in common: they both require
Java to run. While this is the only requirement for the *REST server*,
the *Joex* components requires some more external programs.

### Java

Very often, Java is already installed. You can check this by opening a
terminal and typing `java -version`. Otherwise install Java using your
package manager or see [this site](https://adoptopenjdk.net/) for
other options.

It is enough to install the JRE. The JDK is required, if you want to
build docspell from source.

Docspell has been tested with Java version 1.8 (or sometimes referred
to as JRE 8 and JDK 8, respectively). The pre-build packages are also
build using JDK 8. But a later version of Java should work as well.

The next tools are only required on machines running the *Joex*
component.

### External Tools for Joex

- [Ghostscript](http://pages.cs.wisc.edu/~ghost/) (the `gs` command)
  is used to extract/convert PDF files into images that are then fed
  to ocr. It is available on most GNU/Linux distributions.
- [Unpaper](https://github.com/Flameeyes/unpaper) is a program that
  pre-processes images to yield better results when doing ocr. If this
  is not installed, docspell tries without it. However, it is
  recommended to install, because it [improves text
  extraction](https://github.com/tesseract-ocr/tesseract/wiki/ImproveQuality)
  (at the expense of a longer runtime).
- [Tesseract](https://github.com/tesseract-ocr/tesseract) is the tool
  doing the OCR (converts images into text). It can also convert
  images into pdf files. It is a widely used open source OCR engine.
  Tesseract 3 and 4 should work with docspell; you can adopt the
  command line in the configuration file, if necessary.
- [Unoconv](https://github.com/unoconv/unoconv) is used to convert
  office documents into PDF files. It uses libreoffice/openoffice.
- [wkhtmltopdf](https://wkhtmltopdf.org/) is used to convert HTML into
  PDF files.

The performance of `unoconv` can be improved by starting `unoconv -l`
in a separate process. This runs a libreoffice/openoffice listener
therefore avoids starting one each time `unoconv` is called.

### Example Debian

On Debian this should install all joex requirements:

``` bash
sudo apt-get install ghostscript tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf
```


## Database

Both components must have access to a SQL database. Docspell has
support these databases:

- PostreSQL
- MariaDB
- H2

The H2 database is an interesting option for personal and mid-size
setups, as it requires no additional work. It is integrated into
docspell and works really well. It is also configured as the default
database.

For large installations, PostgreSQL or MariaDB is recommended. Create
a database and a user with enough privileges (read, write, create
table) to that database.

When using H2, make sure that all components access the same database
– the jdbc url must point to the same file. Then, it is important to
add the options
`;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE` at the end
of the url. See the [config page](configure#jdbc) for an example.


## Installing from ZIP files

After extracting the zip files, you'll find a start script in the
`bin/` folder.


## Installing from DEB packages

The DEB packages can be installed on Debian, or Debian based Distros:

``` bash
$ sudo dpkg -i docspell*.deb
```

Then the start scripts are in your `$PATH`. Run `docspell-restserver`
or `docspell-joex` from a terminal window.

The packages come with a systemd unit file that will be installed to
autostart the services.


## Running

Run the start script (in the corresponding `bin/` directory when using
the zip files):

```
$ ./docspell-restserver*/bin/docspell-restserver
$ ./docspell-joex*/bin/docspell-joex
```

This will startup both components using the default configuration. The
configuration should be adopted to your needs. For example, the
database connection is configured to use a H2 database in the `/tmp`
directory. Please refer to the [configuration page](configure) for how
to create a custom config file. Once you have your config file, simply
pass it as argument to the command:

```
$ ./docspell-restserver*/bin/docspell-restserver /path/to/server-config.conf
$ ./docspell-joex*/bin/docspell-joex /path/to/joex-config.conf
```

After starting the rest server, you can reach the web application at
path `/app`, so using default values it would be
`http://localhost:7880/app`.

You should be able to create a new account and sign in. Check the
[configuration page](configure) to further customize docspell.


### Options

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


## Raspberry Pi, and similiar

Both component can run next to each other on a raspberry pi or
similiar device.


### REST Server

The REST server component runs very well on the Raspberry Pi and
similiar devices. It doesn't require much resources, because the heavy
work is done by the joex components.


### Joex

Running the joex component on the Raspberry Pi is possible, but will
result in long processing times for OCR. Files that don't require OCR
are no problem.

Tested on a RPi model 3 (4 cores, 1G RAM) processing a PDF (scanned
with 300dpi) with two pages took 9:52. You can speed it up
considerably by uninstalling the `unpaper` command, because this step
takes quite long. This, of course, reduces the quality of OCR. But
without `unpaper` the same sample pdf was then processed in 1:24, a
speedup of 8 minutes.

You should limit the joex pool size to 1 and, depending on your model
and the amount of RAM, set a heap size of at least 500M
(`-J-Xmx500M`).

For personal setups, when you don't need the processing results asap,
this can work well enough.
