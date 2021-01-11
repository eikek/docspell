# Changelog

## v0.18.0

*Jan 11, 2021 *

- Feature: Results summary and updated tag count (#496, #333)
  - A search summary can be displayed that shows the overall result
    count and to each custom field with a numeric type (number or
    money) small statistics like sum, average and max/min values. This
    is useful when you track your expenses on invoices or receipts.
  - This additional ui element can be enabled/disabled in your ui
    settings.
  - The result summary is now also used to update the tag counts in
    the search menu according to the current results.
- Feature: password reset (#376,
  [docs](https://docspell.org/docs/tools/reset-password/))
  - Adds a new route for admins to reset the password of a user
  - Admin users are those with access to the config file, the endpoint
    requires to supply a secret from the config file.
  - A bash script is provided for more convenient access.
  - *Note this also moves the re-create index endpoint behind the same
    secret!* See below.
- Feature: custom fields clickable (#514)
  - The item detail view allows to click on tags to quickly find all
    tagged items. This now works for custom fields, too.
- Feature: scroll independently (#541)
  - The search menu can scroll now independent from the main area
    containing the item cards.
- Improvement: improve attachment selection (#396)
  - When selecting an attachment, it shows its preview to the name
    instead of the name only
- Improvement: wildcard search for custom date fields (#550)
  - Searching for custom field values allows to use a wildcard `*` at
    beginning or end. This is also enabled for date-fields.
- Improvement: joex memory (#509)
  - Joex currently requires a lot of memory to hold the NLP models.
    After idling for some time, which can be configured and defaults
    to 15 min, the NLP model cache is cleared. This reduces memory
    load and makes it possible for the JVM to give it back to the OS.
  - This is supposed to relieve memory consumption when idling only.
    However, whether it is reclaimed by the OS depends on the JVM and
    its settings. To observe it early, use the G1GC garbage collector.
    This is enabled by default for JDK11. So it is recommended to use
    JDK11 (which is used in the docker images).
- Improvement: allow scaling joex with docker-compose, thanks @bjeanes
  (#552)
  - This allows to easily start multiple joex containers via
    `docker-compose`
- Improvement: allow to connect with gmail via app specific passwords
  (#520)
  - Imap settings have been extended to be able to specify if a OAuth2
    should be used or not.
  - Before, OAuth2 was the default when the server has advertised it.
    *This has been changed now, which means you need to adapt your
    IMAP settings if you currently use OAuth2*
- Fix: provide multiple possible date suggestions for English
  documents (#561)
- Fix: add missing language files to joex docker image (#525)
- Fix: fix a bug that occurs when processing is restarted (i.e. after
  a crash) (#530)
- Fix: fix a bug in the ui where the mail connection field was not
  correctly updated (#524)
- Fix: fix bug when importing mails with an applied filter (#551)

### Breaking Changes

- Rest Server config:
  - If you specify the `fulltext-search.recreate-key`, you need to
    change your config. Delete it and use the secret now for the new
    setting `admin-endpoint.secret`.
- routes
  - The route to drop and recreate the fulltext search index has been
    moved. It is now at `/admin/fts/reIndexAll`. The secret must now
    provided as http header and not in the url.
- collective settings:
  - The imap settings have a new flag which indicates whether OAuth2
    auth mechanism should be prefered. This is `false` by default. If
    you have used it with OAuth2 (like with gmail) you need either set
    this flag to `true` manually or use an [application specific
    password](https://docspell.org/docs/webapp/emailsettings/#via-app-specific-passwords).

### REST Api Changes

- Rest Server:
  - Move endpoint `/open/fts/reIndexAll/{id}` to
    `/admin/fts/reIndexAll`. The secret must now be specified via an
    http header `Docspell-Admin-Secret`.
  - Add `/admin/user/resetPassword` which requires a http header
    `Docspell-Admin-Secret` with a value from the config file.
  - Add `/sec/item/searchStats` to return a search result summary
  - Changes `ImapSettings` to include a `useOAuth` flag
  - Remove `fileCount` from the `TagCloud` structure
  - The return value for `/sec/item/searchStats` now contains all
    tags, before tags with `count == 0` were excluded
  
### Configuration Changes

- Rest Server:
  - adds `admin-endpoint.secret` (without any value) that is the
    secret for the new "admin endpoint"
  - Removes `full-text-search.recreate-key`, the route that was using
    this key is now moved in the admin endpoint and therefore shares
    this secret now.
- Joex:
  - adds `clear-stanford-nlp-interval = "15 minutes"` which is the
    joex idle time to clear the nlp cache
  - The default `pool-size` is set to 1. You can increase it on
    stronger machines.


## v0.17.1

*Dec 15, 2020*

An unfortunate bug has made it into the previous release that makes
the webapp near unusable. Therefore this release, containing only the
fix for #508.

Sorry for the inconvenience!


## v0.17.0

*Dec 14, 2020*

This release comes with some smaller features:

- Feature: Remember-Me – another cookie is used to provide a
  remember-me functionality. The cookie is checked against some value
  in the database, so an admin can always make all remember-me cookies
  invalid. (#435)
- Feature: Link persons to organizations. In the address book, a
  person can now be associated to an organzition. The dropdowns show a
  little hint for which organization a person belongs to. Also
  suggestions for persons are restricted to those of the organization
  if that has been associated before. (#375)
- Feature: Allow to filter on source names. The search form can now
  search by a source name. The new field can be hidden via ui settings
  (it must be activated for exising users). (#390)
- Feature: Customize the title and subtitle of the item card in the
  overview. You can now define patterns for the title and subtitle of
  a card. (#429)
- Feature: Export your data. A bash script has been added that goes
  through your items and downloads them all to disk (including their
  metadata!). This can be used to periodically backup the data in
  docspell.
- Improvement: The webui has been improved in that the search bar and
  search form are unified regarding the text search. The two fields in
  the form, allowing to search in names and fulltext, have been
  combined into a single field just as the search bar. (#497)

This is the last release for 2020. I had hoped to put more into this,
but this time of the year is always a busy one ;-). I want to thank
you for your support and interest in this project and I wish you all a
joyful Christmas time!

### REST Api Changes

- The `Person` structure now takes a reference to the organization.
- `ItemSearch` is extended with the `source` field.
- `UserPass` is extended to include a `rememberMe` flag

### Configuration Changes

- Restserver:
  - a `remember-me` section was added to the `auth` section
- Joex:
  - a `cleanup-remember-me` section was added to the house-keeping
    tasks.


## v0.16.0

*Nov 28, 2020*

This release brings the "custom metadata fields" feature. It allows
you to define custom fields and associate values to your items.
Additionally there are some ui and other fixes and improvements.

- Feature: Custom Fields – define custom metadata fields an set values
  for them on your items. For example, this can be used to track
  invoice numbers, pagination stamps etc. Fields can be defined per
  collective and carry a format (or type). (#41)
- Feature: The language has been added to the metadata of an upload
  request and therefore overrides the collective's default language.
  This means you can now set the document language with each document.
  (#350)
- Feature: Show the currently logged in user and the collective in the
  web app. (#329)
- Feature: Tag categories are presented as a dropdown, where you can
  choose an existing one or type a new one. (#331)
- Feature: The dropdown fields for a person have been changed in that
  the options are now restricted to the corresponding scope: the
  correspondent person only shows persons *not* marked as concerning
  and vice-versa. (#332)
- Feature: Add CC and BCC recipients to item mail (#481)
- The `consumedir.sh` scripts was improved:
  - log a warning for all subfolders that currently wouldn't work due
    to configuration problems
  - ignore hidden files on linux (starting with a dot `.`)
  - include the parameter `skipDuplicates` into the upload request
    when the `-m` option is present
- Fixes a bug that prevented detecting dates in january (#480, thanks
  @vanto!)
- Fixes updating search view after changes like deleting item in
  multi-edit mode or updating tags via drag-and-drop.

The list of issues is
[here](https://github.com/eikek/docspell/milestone/3?closed=1).

### REST Api Changes

- `ItemSearch` is extended to allow searching for custom field values
- `/sec/item/{id}/customfield` route to set values for custom fields
- `/sec/item/{id}/customfield/{fieldId}` route to delete values for
  custom fields on an item
- `/sec/items/customfield`, `/sec/items/customfieldremove` routes to
  set/remove custom field values for multiple items
- `/sec/customfield` routes to manage custom fields
- A lanugage field has been added to `ItemUploadMeta` and
  `ScanMailboxSettings`
- Added `cc` and `bcc` fields to `SimpleMail`

### Configuration Changes

None.


## v0.15.0

*Nov 15, 2020*

This release adds the "preview feature", where a thumbnail of the
first page of each attachment can be shown in the overview. Additional
there are some bugfixes and UI improvements.

- Feature: create a thumbnail of every file. The scale factor can be
  configured in the config file. The user can choose in the ui, what
  size to display and whether to display it or not. (#327)
- Feature: Display the number of pages in the overview (#325)
- Feature: Extend the upload request to allow to specify a file filter
  and a list of tags (#346, #385):
  - file filter: this is a glob that selects files when an archive
    file (a zip or e-mail file) is uploaded
  - tag list: allows to specify a list of tags that are automatically
    set on the item that is being created
  - these two settings are added to the scan-mailbox form and the
    source-form
- Feature: Filter mails to import by subject (#384)
- Feature: Add quick links to item-detail and overview to jump to a
  specific search view; e.g. click on correspondent takes you to the
  overview with this correspondent selected in the search menu (#355)
- Improved css assets (#349)
  - Moved from [Semantic-UI](https://semantic-ui.com/) to
    [Fomantic-UI](https://fomantic-ui.com/), which is an actively
    maintained fork of the former
  - Removed the request to obtain a google font. Now you can use
    docspell without hassle in environments without internet
    connection
  - jquery could be dropped as a js dependency
  - This is a foundation for adding/changing themes eventually.
- Improved ui for multi select mode when selecting items
- Fix a bug when creating new scan-mailbox settings (#382)
- Fix a build issue that resulted in missing scripts in the tools zip
  file.
- Fix a bug that added the `.pdf` extension twice. The filename can
  now be defined in the config file. (#397)

### REST Api Changes

- New endpoints for getting/re-generating preview images:
  - `sec/item/{id}/preview`
  - `sec/attachment/{id}/preview`
  - `sec/collective/previews` to re-generate all previews of a
    collective
- Changes in data structures:
  - `ScanMailboxSettings` adds a list of tags, a file- and subject
    filter
  - `ItemUploadMeta` adds a list of tags and a file filter
  - `SourceList` now contains the `Source` and its associated `Tag`s
  - `Source` has an additional file filter
  - new `SourceTagIn` structure to use when updating/adding sources
  - Renamed `concEquip` to `concEquipment` in `ItemLight`
  - `ItemLight` has an additional `attachments` list containing basic
    infos about the associated attachments

### Configuration Change

- Joex: `….extraction.preview.dpi` to specify the dpi to use when
  creating the thumbnail. Higher value results in better quality
  images, but also larger ones
- Joex: `….convert.converted-filename-part` to specify the part that
  is used for the pdf-converted file


## v0.14.0

*Nov 1st, 2020*

This release contains many bug fixes, thank you all so much for
helping out! There is also a new feature and some more scripts in
tools.

- Edit/delete multiple items at once (#253, #412)
- Show/hide side menus via ui settings (#351)
- Adds two more scripts to the `tools/` section (thanks to
  @totti4ever):
  - one script to import data from paperless (#358, #359), and
  - a script to check clean a directory from files that are already in
    docspell (#403)
- Extend docker image to use newest ocrmypdf version (#393, thanks
  @totti4ever)
- Fix bug that would stop processing when pdf conversion fails (#392,
  #387)
- Fix bug to have a separate, configurable source identifier for the
  integration upload endpoint (#389)
- Fixes ui bug to not highlight the last viewed item when searching
  again. (#373)
- Fixes bug when saving multiple changes to the ui settings (#368)
- Fixes uniqueness check for equipments (#370)
- Fixes a bug when doing document classification where user input was
  not correctly escaped for regexes (#356)
- Fixes debian packages to have both (joex + restserver) the same user
  to make H2 work (#336)
- Fixes a bug when searching with multiple tags using MariaDB (#404)

### REST Api Changes

- Routes for managing multiple items:
  - `/sec/items/deleteAll`
  - `/sec/items/tags`
  - `/sec/items/tagsremove`
  - `/sec/items/name`
  - `/sec/items/folder`
  - `/sec/items/direction`
  - `/sec/items/date`
  - `/sec/items/duedate`
  - `/sec/items/corrOrg`
  - `/sec/items/corrPerson`
  - `/sec/items/concPerson`
  - `/sec/items/concEquipment`
  - `/sec/items/confirm`
  - `/sec/items/unconfirm`
  - `/sec/items/reprocess`
- Adds another parameter to `ItemSearch` structure to enable searching
  in a subset of items giving their ids.

### Configuration Changes

- new setting `….integration-endpoint.source-name` to define the
  source name for files uploaded through this endpoint

## v0.13.0

*Oct 19, 2020*

This release contains bugfixes.

- Improvements to the docker setup: application can be build from any
  version. Thanks to @totti4ever.
  - This change required breaking changes in the `docker-compose.yml`
    file. Please update your `docker-compose.yml` to the new version.
  - The image tags changed:
    - the `-latest` is now upper case, `-LATEST`
    - tagged releases include the version prefixed with a `v`, like in
      `-v0.13.0`
    - there are new `-SNAPSHOT` images that are build from the current
      master branch. *Please note that snapshot versions may not be
      compatible with each other!*
- The date extraction tried to create invalid dates (#298)
- Fixed order of job log entries that was undefined if entries were
  written very fast
- Fix `content` column for MariaDB (#297)
- Fixe regarding retrying processing of files: attached files were not
  correctly found and the duplicate check must not run
- When "home-page" is rendered, do an initial search. This updates the
  view correctly if something changed when coming from item details.
- Reset upload page on init (#294)
- Fixes regarding `base-url` setting and auth cookie (#308)
- Fixes in openapi spec (#338, #343)
- Fixed error messages for modal dialogs (tag/organization/person) (#341)

### REST Api Changes

- No changes, besides some fixes to urls in the spec to be constistent
  to the app.

### Configuration Changes

- No changes.


## v0.12.0

*Sep 28, 2020*

Thanks to a lot of great input from users, this release fixes
annoyances in the ui.

- Improve startup experience wrt the `base-url` setting. Docspell now
  uses request headers to determine absolute urls if this setting is
  unchanged. (#250)
- Fixes scrolling issues when going from detail to list view and vice
  versa. (#254)
- Fix quick search component to keep search term between changes.
  (#261)
- Docspell now provides a valid manifest to be an installable "pwa".
- Fixes `consumedir.sh` script to work with whitespace in filenames.
  (#269)
- Fix hidden fields feature. Hidden fields are now resetted when
  clicking *Confirm*. (#256)
- Improve *Save Name* in item detail: The save button is removed and
  changes are saved while typing. (#255)
- Add keyboard shortcuts in item detail for navigating and
  confirm/unconfirm. (#225)
- Detect duplicate files server side. The processing task is now able
  to detect duplicate files to skip them if desired. The ui has a new
  checkbox when uploading. (#252)
- Improve view of many attachments to an item: The tab menu is
  replaced by a dropdown menu that allows to change attachments also
  on small screens and/or when there are many attachments.

### Configuration Changes

- No changes to default config values.

### REST Api Changes

- Amend `ItemUploadMeta` with a `skipDuplicates` flag for ignoring
  duplicate files on processing.


## v0.11.1

*Sep 09, 2020*

This is a bugfix release. The full-text-index requires a schema
upgrade for the added language that got lost in the previous release.


## v0.11.0

*Sep 07, 2020*

This release didn't change much on the surface, but contains a lot of
improvements for processing files.

- Improves the recognition of correspondents and people in the
  documents. Until now, the analyser didn't know about the existing
  organizations/people of a collective. Now this data is given to the
  analyser as input which results in a higher accuracy when finding
  matches. This may result in high memory usage depending on the size
  of the collective data and therefore can be disabled in the config
  file.
- Adds text classification. Docspell can now learn from your existing
  tagged items. Given a tag category, a statistical model is created
  from your existing documents and used to predict a tag (of that
  category) for new documents. Creating this model may need a lot of
  memory and therefore text classification can be disabled globally
  via the config file. Additionally each collective can enable/disable
  it. Learning is done periodically via a user-task that can be
  configured in the collective settings.
- Adds the language french, supported for text extraction and text
  analysis. 
- Fixes some build failures that produced artifcats with source files.
- Change the job priority of any waiting job from the *Processing*
  page.
- Serving static asset files gzipped, to reduce bandwidth

### Configuration Changes

- New settings in `joex.analysis.regex-ner`, `….classification` and
  `….working-dir` for the classifier and NER feature.
- New setting in `server.show-classification-settings` to hide/show
  the classifier settings on the *Collective Settings* page. If
  classification is disabled globally (i.e. from all joex instances),
  the feature can be hidden from the users.

### REST Api Changes

- `/sec/collective/classifier/startonce` to start the learning task
  separately from the schedule.
- `/sec/queue/{id}/priority` for setting a new priority of a job (only
  for jobs in waiting state)
- The `CollectiveSettings` object is amended with a new
  `ClassifierSetting` object.


## v0.10.0

*Aug 15, 2020*

- Lots of web ui improvements:
  - Rework the search menu for [tags and
    folders](https://docspell.org/docs/webapp/finding/#tags-tag-categories):
    The dropdown field is removed for tags and folders. They are
    represented as a list and items can be cycled through to be
    included/excluded or deselected. It is possible to use
    drag-and-drop to associate tags to items and put items into
    folders.
  - Rework page that displays sources; allow to copy the urls and add
    a qr code
  - Add item notes to the cards in the list view, can be configured if
    it is shown or not (#186, #201)
  - Improve how the item notes are displayed in the item detail view
    (#186, #192)
  - Fix the *Load more…* button
  - Allow to search by tag categories (#203)
  - Allow to edit metadata in item detail view. Until now it was only
    possible to add new metadata (#205)
  - Do not cover the whole screen with the metadata modal dialog, only
    the menu is now covered so that it is possible to select text from
    the document (#205)
  - Allow to hide some fields from the menus. What fields to display
    can be configured in the ui settings (#195)
- Implemented some routes that were specified in the openapi, but have
  not been implemented so far
- Fix source upload routes where it didn't check whether a source is
  enabled or not. Further checks are now done as first step to not
  upload the file into memory for nothing if something fails (e.g. the
  source doesn't exist)
- Re-process files. A
  [route](https://docspell.org/openapi/docspell-openapi.html#api-Item-secItemItemIdReprocessPost)
  has been added that submits files for re-processing. It is possible
  to re-process some files of an item or all. There is no UI for this
  for now. You'd need to run `curl` or something manually to trigger
  it. It will replace all extracted metadata of the *files*,but
  doesn't touch the metadata of the item. (#206)
- Add a task to convert all pdfs using the
  [OCRMyPdf](https://github.com/jbarlow83/OCRmyPDF) tool that can be
  used in docspell since the last release. This task converts all your
  existing PDFs into a PDF/A type pdf including the OCR-ed text layer.
  There is no UI to trigger this task, but a
  [script](https://docspell.org/docs/tools/convert-all-pdf/) is
  provided to help with it. (#206)
- There is now an [Android Client
  App](https://github.com/docspell/android-client) to conveniently
  upload files from your android devices

### Configuration Changes

- New setting `docspell.server.max-note-length` to specify how much of
  the item notes should be transeferred with each search result.

### REST Api Changes

- Added `/sec/collective/tagcloud` to return all used tags of a
  collective. This is the same as returned from the `insights` route,
  but without all the other data.
- Added `/sec/item/convertallpdfs` to trigger a task for converting
  all currently unconverted pdfs
- Added `/sec/item/{id}/taglink` for associating tags given by name or
  id
- Added `/sec/item/{id}/tagtoggle` for toggling tags given by name or
  id
- Added `/sec/item/{id}/reprocess` for submitting an item for being
  re-processed


## v0.9.0

*Aug 1st, 2020*

- New feature: folders. Users can create folders and put items into
  them. Folders can have members (users of the collective) and search
  results are restricted to items that are in no folder or in a folder
  where current user is a member. (see #21)
- Folders can be given to the upload request.
- Add ocrmypdf utility to convert pdf->pdf with ocr-ed text layer.
- Extract PDF metadata and use the *keywords* to search for tags and
  apply them to the item during processing. (See #175)
- Fix duplicate results when doing fulltext only searches
- Several small bug fixes and improvements in the UI
  - Fix position of datepicker (see #186)
  - Fix race condition when updating calendar-event field
  - Sort tags by count in collective-insights view
  - Simplify search bar 
- New website

### Configuration Changes

- Joex: add a section `docspell.joex.convert.ocrmypdf` for configuring
  the ocrmypdf tool.
- Joex: change default value of `….extraction.pdf.min-text-len` from
  10 to 500.

### REST Api Changes

- Add `/sec/folder/*` routes for managing folders.
- Add `/sec/item/{id}/folder` for updating an item folder.
- Change `ItemSearch` structure to be able to search for items in a
  specific folder.
- Change `ItemDetail` and `ItemLight` structure, adding the item folder 
- Change `ItemUploadMeta` structure, adding a folder id field. 
- Change `Source` structure, adding a folder id field. 
- Change `User` structure, adding the user id


## v0.8.0

*June 29, 2020*

- Adds the [full-text
  search](https://docspell.org/docs/webapp/finding/#full-text-search)
  feature (see #69). It requires a separate
  [Solr](https://lucene.apache.org/solr) instance. Items can be
  searched by documents contents and item/file names. It is possible
  to use full-text search to further confine the results via the
  search menu.
- Fixes column types for item date and due-date for MariaDB (see #158)
  and adds an upper limit for due-dates (which is configurable).
- Fixes a bug when cancelling jobs. Stuck jobs were only removed from
  the queue, but their cancel routine was not called.
- Changes in cancelling process-item jobs: the item will still be
  created and not removed.
- Fixes a bug where items could not be deleted if there were sent
  mails attached.
- Fixes the openapi spec for the joex component. This made the
  generated live documentation unusable.
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
  a lower-cased value (see #147).
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
