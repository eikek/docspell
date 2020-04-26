# Changelog

## v0.5.0

*Unknown*

- Allow to delete attachments of an item.
- Allow to be notified via e-mail for items with a due date. This uses
  the periodic-task framework introduced in the last release.
- Fix issues when converting HTML with unkown links. This especially
  happens with e-mails that contain images to attachments.
- Fix issues when importing e-mail files:
  - fixes encoding problems for mails without explicit transfer encoding
  - add meta info (from, to, subject) to the converted pdf document
  - clean html mails to remove unwanted content (like javascript)
- Fix classpath issue with javax.mail vs jakarta.mail

## v0.4.0 

*Mar. 29, 2020*

- Support for archive files. Archives, for example zip files, contain
  the files that should go into docspell. Docspell now extracts
  archives and adds the content to an item. The extraction process is
  recursive, so there may be zip files in zip files. File types
  supported:
  - `zip` every file inside is added to one item as attachment
  - `eml` (RCF822 E-Mail files) E-mails are considered archives, since
    they may contain multiple files (body and attachments).
- Periodic Tasks framework: Docspell can now run tasks periodically
  based on a schedule. This is not yet exposed to the user, but there
  are some system cleanup jobs to start with. 
- Improvement of the text analysis. For my test files there was a
  increase in accuracy by about 10%.
- A due date that is found during text analysis is now set on the
  item. If multiple due dates are found, the earliest one is used.
- Allow to switch between viewerjs PDF viewer or the browser's builtin
  viewer.
- Bug fixes related to handling text files.
- Add a configurable length limit for text analysis

### Configuration Changes

The configuration of the joex component has been changed. 

- new section `docspell.joex.periodic-scheduler` for configuring the
  periodic scheduler
- new section `docspell.joex.house-keeping` for configuring
  house-keeping tasks
- new section `docspell.joex.text-analysis` for configuring the new
  size limit
- The command for running `wkhtmltopdf` changed in that the encoding
  is now added at runtime.

### REST Api Changes

The REST Api has some additions:

- new route to retrieve the archive file
- add field in `ItemDetail` data that refers to the archive files of
  the attachments


## v0.3.0

*Mar. 1, 2020*

- Support for many more document types has been added (including
  images and office documents). All input files are converted into PDF
  files (the original file is preserved).
- PDF Text extraction improved by omitting OCR if text can be
  stripped.
- There is a new PDF viewer (utilizing viewerjs) that also works in
  mobile browsers.
- Improve editing notes: Since notes may evolve, there is now a larger
  edit form and a markdown preview.
- Show the extracted information (text, labels, proposals) of an
  attachment in the Webui.
- The name search now also searches in item notes.
- Bug fixed where it was possible to create invalid input when
  creating new sources.
- Bug fixed where the item menu was not properly initialized for
  equipments.
- The `ds.sh` script has now an option to check a file for existence
  in docspell.

### Configuration Changes

The configuration of the joex component has been changed. 

- removed `docspell.joex.extraction.allowed-content-types`
- other settings in `docspell.joex.extraction` have been moved to
  `docspell.joex.extraction.ocr`
- added `docspell.joex.extraction.ocr.max-image-size`
- added `docspell.joex.extraction.pdf.min-text-len`
- added sections in `docspell.joex.convert` for pdf conversion
  settings
  
### REST Api Changes

The REST Api has some additions:

- new route to retrieve the original file
- new route to get the rendered pdf of an attachment (using viewerjs)
- add field in `ItemDetail` data that refers to the original files of
  the attachments
  

## v0.2.0

*Jan. 12, 2020*

The second release of Docspell addresses some annoying issues in the
UI and adds a "send by email" feature.

- Send an item and its attachments via E-Mail (requires to setup SMTP
  settings per user)
- Add a search field for meta data
- The item detail view is now a perma-link
- New endpoints to check whether a file is in Docspell by using their
  SHA-256 checksum (see the api doc here and here), the scripts in
  tools/ now use this endpoint to skip existing files
- Better support multiple attachments with long names in the UI
- Fixes textarea updating issues

## v0.1.0

*Sep. 21, 2019*

The initial release of Docspell containing the basic features with a
Web UI:

- Create items by uploading PDF files
- Analyze the PDF files and propose meta data
- Manage meta data and items
- View processing queue
