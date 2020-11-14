+++
title = "Features and Limitations"
weight = 10
insert_anchor_links = "right"
description = "A list of features and limitations."
+++

# Features

- Multi-account application
- Multiple users per account (multiple users can access the same
  account)
- Handle multiple documents as one unit
- OCR using [tesseract](https://github.com/tesseract-ocr/tesseract)
- [Full-Text Search](@/docs/webapp/finding.md#full-text-search) based
  on [Apache SOLR](https://lucene.apache.org/solr)
- Conversion to PDF: all files are converted into a PDF file. PDFs
  with only images (as often returned from scanners) are converted
  into searchable PDF/A pdfs.
- Non-destructive: all your uploaded files are never modified and can
  always be downloaded untouched
- Organize files using tags, folders and other
  [metadata](@/docs/webapp/metadata.md)
- Text is analysed to find and attach meta data automatically
- *Keywords* metadata from pdf files is extracted and matched against
  tags in the database
- [Manage document processing](@/docs/webapp/processing.md): cancel
  jobs, set priorities
- Everything available via a [documented](https://www.openapis.org/)
  [REST Api](@/docs/api/_index.md); allows to [generate
  clients](https://openapi-generator.tech/docs/generators) for
  (almost) any language
- mobile-friendly Web-UI
- [Create “share-urls”](@/docs/webapp/uploading.md#anonymous-upload)
  to upload files anonymously
- [Send documents via e-mail](@/docs/webapp/mailitem.md)
- [E-Mail notification](@/docs/webapp/notifydueitems.md) for documents
  with due dates
- [Read your mailboxes](@/docs/webapp/scanmailbox.md) via IMAP to
  import mails into docspell
- [Edit multiple items](@/docs/webapp/multiedit.md) at once
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
- Tooling:
  - [Android App](@/docs/tools/android.md) to quickly upload files
    from your android devices
  - [Watch a folder](@/docs/tools/consumedir.md): watch folders for
    changes and send files to docspell
  - [Simple CLI for uploading files](@/docs/tools/ds.md)
  - [Firefox plugin](@/docs/tools/browserext.md): right click on a
    link and send the file to docspell
  - [SMTP Gateway](@/docs/tools/smtpgateway.md): Setup a SMTP server
    that delivers mails directly to docspell.
  - [Paperless Import](@/docs/tools/paperless-import.md) for importing
    your data from paperless
  - [Directory Cleaner](@/docs/tools/consumedir-cleaner.md) clean
    directories with files that have been uploaded to docspell
- License: GPLv3


# Limitations

These are current known limitations that may be of interest for
considering docspell at the moment.

- Documents cannot be modified.
- You can remove and add documents but there is no versioning.
