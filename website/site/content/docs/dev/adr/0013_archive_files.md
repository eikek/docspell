+++
title = "Archive Files"
weight = 140
+++


# Context and Problem Statement

Docspell should have support for files that contain the actual files
that matter, like zip files and other such things. It should extract
its contents automatcially.

Since docspell should never drop or modify user data, the archive file
must be present in the database. And it must be possible to download
the file unmodified.

On the other hand, files in there need to be text analysed and
converted to pdf files.

# Decision Outcome

There is currently a table `attachment_source` which holds references
to "original" files. These are the files as uploaded by the user,
before converted to pdf. Archive files add a subtlety to this: in case
of an archive, an `attachment_source` is the original (non-archive)
file inside an archive.

The archive file itself will be stored in a separate table `attachment_archive`.

Example: uploading a `files.zip` ZIP file containing `report.jpg`:

- `attachment_source`: report.jpg
- `attachment`: report.pdf
- `attachment_archive`: files.zip

Archive may contain other archives. Then the inner archives will not
be saved. The archive file is extracted recursively, until there is no
known archive file found.

# Initial Support

Initial support is implemented for ZIP and EML (e-mail files) files.
