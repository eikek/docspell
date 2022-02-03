+++
title = "Features and Limitations"
weight = 9
insert_anchor_links = "right"
description = "A list of features and limitations."
template = "docs.html"
+++

# Features

- Multi-account application
- Multiple users per account (multiple users can access the same
  account)
- Handle multiple documents as one unit
- OCR using [tesseract](https://github.com/tesseract-ocr/tesseract)
- [Full-Text Search](@/docs/webapp/finding.md#full-text-search) based
  on [Apache SOLR](https://solr.apache.org)
- Conversion to PDF: all files are converted into a PDF file. PDFs
  with only images (as often returned from scanners) are converted
  into searchable PDF/A pdfs.
- A powerful [query language](@/docs/query/_index.md) to find
  documents
- use [bookmarks](@/docs/webapp/bookmarks.md) to save more complex queries
- customizable [dashboards](@/docs/webapp/dashboards.md) as the main page
- Non-destructive: all your uploaded files are never modified and can
  always be downloaded untouched
- Organize files using tags, folders, [Custom
  Fields](@/docs/webapp/customfields.md) and other
  [metadata](@/docs/webapp/metadata.md)
- Text is analysed to find and attach meta data automatically
- *Keywords* metadata from pdf files is extracted and matched against
  tags in the database
- [Manage document processing](@/docs/webapp/processing.md): cancel
  jobs, set priorities
- Everything available via a [documented](https://www.openapis.org/)
  [REST Api](@/docs/api/_index.md); allows to [generate
  clients](https://openapi-generator.tech/docs/generators) for many
  languages
- [OpenID Connect](@/docs/configure/_index.md#openid-connect-oauth2)
  support allows Docspell to integrate into your SSO setup, for
  example with keycloak.
- Two-Factor Authentication using [TOTP](@/docs/webapp/totp.md) built
  in
- mobile-friendly Web-UI with dark and light theme
- [Create anonymous
  “upload-urls”](@/docs/webapp/uploading.md#anonymous-upload) to
  upload files; these urls allow to be configured with metadata like
  tags, folder etc that are applied to all files uploaded through this
  url
- [Share](@/docs/webapp/share.md) documents via cryptic public links
  (optionally protected by a password)
- [Send documents via e-mail](@/docs/webapp/mailitem.md)
- [Notifications](@/docs/webapp/notification.md) for documents with
  due dates or events via E-Mail, [Matrix](https://matrix.org) or
  [Gotify](https://gotify.net)
- [Read your mailboxes](@/docs/webapp/scanmailbox.md) via IMAP to
  import mails into docspell
- [Edit multiple items](@/docs/webapp/multiedit.md) at once
- [Merge](@/docs/webapp/merge.md) multiple items
- REST server and document processing are separate applications which
  can be scaled-out independently
- Everything stored in a SQL database: PostgreSQL, MariaDB or H2
  - H2 is embedded, a "one-file-only" database, avoids installing db
    servers
- Support for encrypted PDFs
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
  - [Command Line Interface](@/docs/tools/cli.md) allowing to upload
    files, watch folders and many more!
  - [Android App](@/docs/tools/android.md) to quickly upload files
    from your android devices
  - [SMTP Gateway](@/docs/tools/smtpgateway.md): Setup a SMTP server
    that delivers mails directly to docspell.
- License: AGPLv3


# Limitations

These are current known limitations that may be of interest for
considering docspell at the moment.

- Documents cannot be modified.
- You can remove and add documents but there is no versioning.
- There is no fine grained permission management
