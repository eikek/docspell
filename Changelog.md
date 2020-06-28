# Changelog

## v0.8.0

*Soon*

- Adds the [full-text
  search](https://docspell.org/doc/finding#full-text-search) feature
  (see #69). It requires a separate
  [Solr](https://lucene.apache.org/solr) instance. Items can be
  searched by documents contents and item/file names. It is possible
  to use full-text search to further confine the results via the
  search menu.
- Fixes column types for item date and due-date for MariaDB (see #158)
  and adds an upper limit for due-dates (which is configurable).
- Fixes a bug when cancelling jobs where stuck jobs were only removed
  from the queue, but their cancel routine was not called.
- Changes cancelling process-item jobs, the item will still be created
  and not removed.
- Fixes a bug where items could not be deleted if there were sent
  mails attached.
- Fixes the openapi spec for the joex component.
- Changes to the `consumedir.sh` script:
  - Allow to recursively watch or traverse directories
  - Allow it to work with the integration endpoint. This allows using
    `consumedir.sh` for all collectives.
- The docker setup now starts a solr container automatically and
  configures the consumedir container to use the integration endpoint.
  It is still necessary to define an environment variable.

### Configuration Changes

- Set new default for `docspell.server.max-item-page-size` to `200`.
- New `full-text-search` section for restserver and joex.

### REST Api Changes

- Add `/open/fts/reIndexAll/{key}` to re-index the full-text search
  index. The `key` must be defined in the config file, so only admins
  can execute this.
- Add `/sec/fts/reIndex` to allow a collective to re-index their data
  only.
- Add `/open/integration/checkfile/{id}/{checksum}` to check whether a
  file is in docspell via the integration endpoint.
- Add `/sec/item/searchIndex` to allow searching the full-text index
  only. This route returns the results as ordered by SOLR and not
  ordered by date.
- The `ItemSearch` input data is extended to support the new full-text
  search field.
- The `ItemLight` result structure now can contain "highlighting"
  information that is provided by the full-text search index.

## v0.7.0

*June 17, 2020*

- Document integration endpoint and add a `GET` route to check it.
- Add webui settings for the user. These settings only apply to the
  web client and are stored in the browser's local storage.
- Enable paging in the item list view. The page size can be set in the
  new client settings. If the number of results is equal to this size,
  a button at the end of the page allows to load more.
- The item list now contains all tags of an item.
- The tag colors can be customized in the client settings. A color per
  tag *category* can be defined.
- New meta data (tags, correspondents, concerned entities) can be
  created directly in the item detail view (see #138). No need to
  navigate away to the *Manage Data* page.
- Fixes a bug in the dropdown widgets that would present items that
  have already been selected.
- Allow to have multiple notify-due-items tasks.
- New *simple search* feature: The list view now appears without the
  search menu by default. A search bar is shown instead that allows to
  search in item name and notes and in names of correspondents and
  concerned entities. The search menu can be opened as before. The
  *name* search field now only searches in item names (as before
  0.3.0), i.e. it doesn't search item notes anymore, which is now
  possible with the *allNames* search field.
- Fixes a bug where a search term was not lower-cased but compared to
  a lower-cased value.
- Allow to change names of attachments. 
- Document how to create a SMTP gateway to docspell and provide a
  simple docker based setup. This is a SMTP server that delivers mails
  to docspell instead of using a mbox or maildir. It utilises the
  integration endpoint.

### Configuration Changes

- Add `docspell.server.max-item-page-size` for a hard limit of the
  page size when fetching items.
- Changed default value of
  `docspell.server.integration-endpoint.allowed-ips.enabled` to
  `false`.
- Add `docspell.server.backend.mail-debug` to allow debug mail related
  problems.

### REST Api Changes

- Add `GET /open/integration/item/{id}` to allow checking the
  integration endpoint.
- Change all routes to update item properties (name, tags, direction,
  corrOrg, corrPerson, concPerson, concEquipment, notes, date,
  duedate) from `POST` to `PUT`.
- Add corresponding `POST` routes to create and update meta data in
  one call. This is only applicable: corrOrg, corrPerson, tags,
  concPerson, concEquipment.
- Add `POST /sec/attachment/{id}/name` to change the name of an
  attachment.
- Change `/sec/usertask/notifydueitems` to return a list of
  notification settings.
- Change the `POST` route to `/sec/usertask/notifydueitems` to only
  create new notification tasks.
- Add a `PUT` route to `/sec/usertask/notifydueitems` to update
  existing notification tasks.
- Add a `GET` and `DELETE` route to
  `/sec/usertask/notifydueitems/{id}` to retrieve or delete a specific
  notification task.
- The `ItemSearch` structure is extended to allow specifying `offset`
  and `limit` for paging (which is required now). It also has an
  optional property `allNames` to provide the search term for the new
  *simple search* feature.
- The `ItemLight` structure has now a list of tags.

## v0.6.0

*May 25th, 2020*

- New feature "Scan Mailboxes". Docspell can now read mailboxes
  periodically to import your mails.
- New feature "Integration Endpoint". Allows an admin to upload files
  to any collective using a separate endpoint.
- New feature: add files to existing items.
- New feature: reorder attachments via drag and drop.
- The document list on the front-page has been rewritten. The table is
  removed and documents are now presented in a “card view”.
- Amend the mail-to-pdf conversion to include the e-mail date.
- When processing e-mails, set the item date automatically from the
  received-date in the mail.
- Fixes regarding character encodings when reading e-mails.
- Fix the `find-by-checksum` route that, given a sha256 checksum,
  returns whether there is such a file in docspell. It falsely
  returned `false` although documents existed.
- Fix webapp for mobile devices.
- Fix the search menu to remember dates in fields. When going back
  from an item detail to the front-page, the search menu remembers the
  last state, but dates were cleared.
- Fix redirecting `/` only to `/app`.

### Configuration Changes

The joex and rest-server component have new config sections:

- Add `docspell.joex.mail-debug` flag to enable debugging e-mail
  related code. This is only useful if you encounter problems
  connecting to mail servers.
- Add `docspell.joex.user-tasks` with a `scan-mailbox` section to
  configure the new scan-mailbox user task.
- Add `docspell.joex.files` section that is the same as the
  corresponding section in the rest server config.
- Add `docspell.server.integration-endpoint` with sub-sections to
  configure an endpoint for uploading files for admin users.

### REST Api Changes

- Change `/sec/email/settings` to `/sec/email/settings/smtp`
- Add `/sec/email/settings/imap`
- Add `/sec/usertask/scanmailbox` routes to configure one or more
  scan-mailbox tasks
- The data used in `/sec/collective/settings` was extended with a
  boolean value to enable/disable the "integration endpoint" for a
  collective.
- Add `/sec/item/{itemId}/attachment/movebefore` to move an attachment
  before another.


## v0.5.0

*May 1st, 2020*

- Allow to delete attachments of an item.
- Allow to be notified via e-mail for items with a due date. This uses
  the periodic-task framework introduced in the last release.
- Fix issues when converting HTML with unkown links. This especially
  happens with e-mails that contain images to attachments.
- Fix various issues when importing e-mail files, for example:
  - fixes encoding problems for mails without explicit transfer encoding
  - add meta info (from, to, subject) to the converted pdf document
  - clean html mails to remove unwanted content (like javascript)
- Fix classpath issue with javax.mail vs jakarta.mail

### Configuration Changes

The Joex component has config changes:

- A new section `send-mail` containing a `List-Id` e-mail header to
  use. Use an empty string (the default) to avoid setting such header.
  This header is only applied for notification mails.


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
