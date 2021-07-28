+++
title = "Paperless Import"
description = "Import your data from paperless."
weight = 60
+++

# Introduction

Coming from
[paperless](https://github.com/the-paperless-project/paperless/), the
script in `tools/import-paperless` can be used to get started by
importing your data from paperless into docspell.

<https://github.com/eikek/docspell/tree/master/tools/import-paperless>

The script imports the files and also tags and correspondents.

# Usage

Copy the script to the machine where paperless is running. Run it with
the following arguments:

1. URL of Docspell, including http(s)
2. Username for Docspell, possibly including Collective (if other name as user)
3. Password for Docspell
4. Path to Paperless' database file (`db.sqlite3`). When using Paperless with docker, it is in the mapped directory `/usr/src/paperless/data`
5. Path to Paperless' document base directory. When using Paperless with docker, it is the mapped directory `/usr/src/paperless/media/documents/origin/`

Some settings can be changed inside the script, right at the top:

* `LIMIT="LIMIT 0"` (default: inactive): For testing purposes, limits
  the number of tags and correspondents read from Paperless (this will
  most likely lead to warnings when processing the documents)
* `LIMIT_DOC="LIMIT 5"` (default: inactive): For testing purposes,
  limits the number of documents and document-to-tag relations read
  from Paperless
* `SKIP_EXISTING_DOCS=true` (default: true): Won't touch already
  existing documents. If set to `false` documents, which exist
  already, won't be uploaded again, but the tags, correspondent, date
  and title from Paperless will be applied.

  **Warning** In case you already had set these information in Docspell,
  they will be overwritten!
