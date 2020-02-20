---
layout: docs
title: Features and Limitations
---

# Features

- Multi-account application
- Multiple users per account
- Handle multiple documents as one unit
- OCR using [tesseract](https://github.com/tesseract-ocr/tesseract)
- Conversion to PDF: all files are converted into a PDF file
- Text is analysed to find and attach meta data automatically
- Manage document processing (cancel jobs, set priorities)
- Everything available via a documented [REST Api](api)
- Web-UI included
- Create “share-urls” to upload files anonymously
- Send documents via e-mail
- REST server and document processing are separate applications which
  can be scaled-out independently
- Everything stored in a SQL database: PostgreSQL, MariaDB or H2
- Files supported:
  - PDF
  - common MS Office (doc, docx, xls, xlsx)
  - OpenDocument (odt, ods)
  - RichText (rtf)
  - Images (jpg, png, tiff)
  - HTML
  - text/* (treated as Markdown)
- Tools:
  - Watch a folder: watch folders for changes and send files to docspell
  - Firefox plugin: right click on a link and send the file to docspell
  - Simple CLI for uploading files
- License: GPLv3


# Limitations

These are current known limitations that may be of interest for
considering docspell at the moment. Hopefully they will be resolved
eventually….

- No fulltext search implemented. This currently has very low
  priority, because I myself never needed it. Open an issue if you
  find it important.
