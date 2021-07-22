+++
title = "FAQ"
weight = 100
description = "Frequently asked questions."
insert_anchor_links = "right"
[extra]
mktoc = true
+++

# FAQ

## Where are my files stored?

Everything, including all files, are stored in the database.

Now that seems to put off some people coming to Docspell, so here are
some thoughts on why this is and why it may be not such a big deal. It
was a conscious decision and the option to hold all files in the file
system was considered, but not chosen in the end.

First, it was clear that a database *is* required in order to support
the planned features. It is required to efficiently support a
multi-user application: the account data, passwords and many other
things (tags, metadata etc) must be stored and queried reliably. Very
often a relational model emerges and a database is the best fit,
otherwise one would just "reinvent the wheel". So the options are to
have a database *and* files in the filesystem or everything in one
database. There are, of course, pros and cons for both ways, these
were the reasons for the current decision:

- Backups: With two things, you have to take care to backup both. All
  supported databases have good support for backups so having just one
  thing to backup is (usually) better than having to backup two
  things. YMMV if you already have some backups system in place.
- Simpler, easier to maintain application: there is just one storage
  system used by the application and not two which reduces complexity
  in the code.
- Consistency: Both "databases" (filesystem + relational db) can
  easily get out of sync and this will break the application. It's a
  very strong plus to be able to rely on the strong ACID guarantees of
  database systems.
- Distributed/Scaling: One goal is to run Docspell in a distributed
  way. If files were on the filesystem, the problem is that they have
  to be transferred to all the nodes eventually. This is trivially
  solved to use the database as a central storage and synchronization
  point.
- Support for binary files in today's databases is not that bad.
  Docspell has no intention to store very large files. It will be
  quite efficient. I've used it several times and never had problems
  related to this.
  [This](https://wiki.postgresql.org/wiki/BinaryFilesInDB) postgres
  page shows some pros and cons.
- The advantage of having files in the filesystem is weakened, if
  files have to be stored using some hash of filenames which might be
  necessary in order to overcome certain file-system limitations.
- For low-volume/traffic installations where you just don't want to
  run a real database server, you can use the
  [H2](https://h2database.com) database. This is an in-process
  database (comparable to sqlite) and doesn't require another server
  running.

You can find more in these issues:
[270](https://github.com/eikek/docspell/issues/270),
[289](https://github.com/eikek/docspell/issues/289#issuecomment-700843894).


## What's the Exit Strategy then?

Of course, there is no guarantee that this project will be alive in
the future. It is important to know how to use your data then.

A very important thing is: it is FREE software (as in freedom and in
beer). That is, you can be sure to use the current version for as long
as you want. So it is a good idea to backup the releases (or docker
images) you are using alongside with your data. This ensures that you
will be able to *use* your data "forever". This also means that you
can inspect the data model and use the api and/or standard SQL tools
to get all the data. While this may be difficult/inconvenient, the
point here is only that it is possible. It's not hidden or obscured,
nothing is lost. You can even backup the sources to keep this
documentation, too.

In order to move to a different tool, it is necessary to get the data
out of Docspell in a machine readable/automatic way. Currently, there
is a [export-files.sh](@/docs/tools/export-files.md) script provided
(in the `tools/` folder) that can be used to download all your files
and item metadata.

My recommendation is to run periodic database backups and also store
the binaries/docker images. This lets you re-create the current state
any time which allows to postpone the problem of getting the data in a
specific format out of Docspell.

Note that you don't need to backup the SOLR instance (if you're using
fulltext search), since it can be recreated by Docspell.


## What if my documents already contain OCR-ed text?

Documents are not ocr-ed twice normally. Doscpell first extracts the
text from a pdf. If this is below some configurable minimum length, it
will still run OCR just to see if that gives more. Then the longer of
the texts is taken. By default it will hand all pdfs to ocrmypdf, but
this will skip already ocred files. The whole ocrmypdf process can be
switched off in the config file. So if you only have these pdfs, this
would be an option, I guess. Alternatively, it is possible to change
the ocrmypdf options in docspell's config file to fit your
requirements.


## Is there support for migrating from other tools?

Currently there exists a bash script to import files and metadata from
[Paperless](https://github.com/the-paperless-project/paperless/).
Please see this [issue](https://github.com/eikek/docspell/issues/358).

## Why another DMS?

Back when Docspell started, there weren't as many options as there are
now. I wanted to try out a different approach.

## Wh…?

If you have any questions, don't hesitate to ask. You can open an
[issue](https://github.com/eikek/docspell/issues/new/choose) or leave
a message in the [gitter](https://gitter.im/eikek/docspell) room. If
you don't want to sign-up there, drop a mail to `info` at
`docspell.org`.
