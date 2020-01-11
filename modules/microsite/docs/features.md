---
layout: docs
title: Features and Limitations
---

# Features

- Multi-account application
- Multiple users per account
- Handle multiple documents as one unit
- OCR using [tesseract](https://github.com/tesseract-ocr/tesseract)
- Text is analysed to find and attach meta data automatically
- Manage document processing (cancel jobs, set priorities)
- Everything available via a documented [REST Api](api)
- Web-UI included
- Create “share-urls” to upload files anonymously
- Send documents via e-mail
- REST server and document processing are separate applications which
  can be scaled-out independently
- Everything stored in a SQL database: PostgreSQL, MariaDB or H2
- Tools:
  - Watch a folder: watch folders for changes and send files to docspell
  - Firefox plugin: right click on a link and send the file to docspell
  - Simple CLI for uploading files
- License: GPLv3


# Limitations

These are current known limitations that may be of interest for
considering docspell at the moment. Hopefully they will be resolved
eventually….

- Only PDF files possible for now.
- The PDF view in the Web-UI relies on the browsers capabilities.
  Sadly, not all browsers can display PDF files. Some may require
  extra plugins. And it's especially sad, that mobile browsers wont't
  display the files. It works with the major desktop browsers
  (firefox, chromium), though.
