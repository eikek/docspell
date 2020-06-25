---
layout: docs
title: Features and Limitations
permalink: features
---

# Features

- Multi-account application
- Multiple users per account (multiple users can access the same
  account)
- Handle multiple documents as one unit
- OCR using [tesseract](https://github.com/tesseract-ocr/tesseract)
- [Full-Text Search](doc/finding#full-text-search) based on [Apache
  SOLR](https://lucene.apache.org/solr)
- Conversion to PDF: all files are converted into a PDF file
- Non-destructive: all your uploaded files are never modified and can
  always be downloaded untouched
- Text is analysed to find and attach meta data automatically
- [Manage document processing](doc/processing): cancel jobs, set
  priorities
- Everything available via a [documented](https://www.openapis.org/)
  [REST Api](api); allows to [generate
  clients](https://openapi-generator.tech/docs/generators) for
  (almost) any language
- mobile-friendly Web-UI
- [Create “share-urls”](doc/uploading#anonymous-upload) to upload files
  anonymously
- [Send documents via e-mail](doc/mailitem)
- [E-Mail notification](doc/notifydueitems) for documents with due dates
- [Read your mailboxes](doc/scanmailbox) via IMAP to import mails into
  docspell
- REST server and document processing are separate applications which
  can be scaled-out independently
- Everything stored in a SQL database: PostgreSQL, MariaDB or H2
  - H2 is embedded, a "one-file-only" database, avoids installing db
    servers
- Files supported:
  - Documents:
    - PDF
    - common MS Office (doc, docx, xls, xlsx)
    - OpenDocument (odt, ods)
    - RichText (rtf)
    - Images (jpg, png, tiff)
    - HTML
    - text/* (treated as Markdown)
  - Archives (extracted automatically, can be nested)
    - zip
    - [eml](https://en.wikipedia.org/wiki/Email#Filename_extensions)
      (e-mail files in plain text MIME)
- [Tooling](doc/tools):
  - [Watch a folder](doc/tools/consumedir): watch folders for changes
    and send files to docspell
  - [Simple CLI for uploading files](doc/tools/ds)
  - [Firefox plugin](doc/tools/browserext): right click on a link and
    send the file to docspell
  - [SMTP Gateway](doc/tools/smtpgateway): Setup a SMTP server that
    delivers mails directly to docspell.
- License: GPLv3


# Limitations

These are current known limitations that may be of interest for
considering docspell at the moment.

- Documents cannot be modified.
- You can remove and add documents but there is no versioning.
