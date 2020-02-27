# Changelog

## v0.3.0

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
