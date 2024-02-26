# Changelog

## v0.41.0

*Jan 29th, 2024*

- Add khmer language (#2011)
- Replace blaze with ember (http stack) (#2221, #2348)
- Updated several dependencies (#2348, #2354, 2355)
- Fix `AddonExecutionResult` monoid (#2363)
- Setting item date from addons (#2345)
- Fix sql queries where a space was missing (#2367, #2368)
- Change AWS region for minio file backend (#2386)
- Allow additional metadata to be passed on upload for addons and hooks (#2334)
- Add support for Slovak language
- Fix possibility to configure too large `session-valid` values (#2309)
- Consider emails when `flattenArchives` is true (#2063)
- Allow new file upload without hitting reset (#2323)

Big thanks to:
- @eikek
- @madduck
- @mprasil
- @rehanone
- @v6ak
- @xshadowlegendx

## v0.40.0

*Mar 11th, 2023*

- Add Ukrainian language (#1835, @GooRoo)
- webui: normalize `,` to `.` for numeric fields
- improve error reporting when file backend fails (#1976)
- docker: remove exlpicit zlib install (#1863)
- nix: replace wkhtmltopdf with weasyprint (#1873, #1895, @VTimofeenko)
- fix listing shares with no name (#1840)
- fix html conversion of text files (#1915)
- fix: remove test-scoped dependencies from artifacts (#1856)
- fix deletin users (#1941)
- fix notification for collective scoped tasks (#1987)

### Rest API changes

- None

### Configuration Changes

- None

## v0.39.0

*Nov 7th, 2022*

- Allow to set extracted content (#1775) You can now fix OCRed text
  this way.
- Improve handling mixes of OIDC and local accounts (#1827). It is now
  possible to use the same account locally and via OIDC.
- Add Estonian language (#1646)
- Updated docker images to new alpine and openjdk, fixing #1736
  (#1713) by @jberggg and @eikek
  - drops support for arm7 (#1719)
  - introduces `weasyprint` as an alternative to `wkhtmltopdf` for
    converting html files to pdf
- Fix docspell's query to remove `attach.count`. It has been removed a
  while ago, but the query language didn't reflect it (#1758)
- Fix search for linked items (#1808)
- Fix item selection after merging (#1809)
- Internal changes to how a collective is referenced as a preparation
  for #585 (#1686)
- Update H2 to 2.1.x, incompatible to the previous used version
  (#1690)

### PLEASE NOTE

The database structure changed substantially in this release. Please
make sure to create a backup of your database **before** attempting
the upgrade!

### Docker Users

There are two major changes for docker users: First ARM7 support has
been dropped, because it was too much work to maintain alongside the
other architectures. Second the images have been updated to the latest
alpine linux, which requires to sacrifice using `wkhtmltopdf` as a
tool to convert HTML to PDF (often used for processing emails).

The joex image doesn't have the `wkhtmltopdf` binary anymore, because
it is not available for alpine linux. Instead `weasyprint` has been
added. Docspell by default still uses `wkhtmltopdf`, because I found
it has better results. But you can now switch to `weasyprint` and if
you use the provided docker images you _have to_.

There is a new config that you need to set - when using environment
variables:

```
DOCSPELL_JOEX_CONVERT_HTML__CONVERTER=weasyprint
```

Just add it to the env variables in the `docker-compose.yml`. If you
use a config file, add this to it:

```
docspell.joex {
  convert.html-converter = "weasyprint"
}
```

### File Backends

The internal change on how collectives are now referenced requires to
adopt the files accordingly. If you have your files in the database,
all is being migrated automatically on first start.

For other file backends, the files must be migrated manually. The
difference is that from now on a collective is referenced by a unique
number and not by its name anymore. You can look at the table
`collective` to see which number was assigned to a collective and then

- for a filebackend, simply move the folder with a collective name to
  its corresponding number
- for s3 backend the same must happen, using some s3 client (maybe
  [this
  one](https://min.io/docs/minio/linux/reference/minio-mc/mc-mv.html))

### H2 

If you use H2 as a database, there are some manual steps required. H2
was bumped from 1.4.x to 2.1.x and the new version cannot read the
database files of the old version.

Additionally, one of the changesets for H2 used a now illegal syntax
and had to be changed. This will lead to checksum mismatch errors when
starting up.

Creating and restoring a dump, the script `tools/h2-util.sh` can be
used. The H2 version can be specified with an environment variable
`H2_VERSION` to easily create a dump in one version and restore in
another.

To fix the changeset, you could simply run this sed command on the
dump before restoring:

```
sed -i 's,175554607,-276220379,g' docspell-dump-h2.sql
```

But this could potentially change not only the checksum, but other
things in the dump. It is not very likely, though. A more safe
alternative is to use a text editor and find the correct place to
change or just set `database-schema.repair-schema = true` in the
config file or use the env variables

```
DOCSPELL_SERVER_BACKEND_DATABASE__SCHEMA_REPAIR__SCHEMA=true
```

and startup only the restserver one time to have the checksum fixed.
Another safe variant is to run this update statement on your h2
database:

```sql
UPDATE flyway_schema_history set checksum = -276220379 WHERE version = '1.9.3';
```


### Rest API changes

- Adds apis for retrieving and setting extracted text at
  `/sec/attachment/{id}/extracted-text`


### Configuration Changes

Restserver:
- Adds `auth.on-account-source-conflict` to decide what to do if an
  account exists locally and at some OIDC provider

Joex:
- Adds a new system command for `weasyprint` an alternative to
  `wkhtmltopdf`
- Adds the setting `convert.html-converter` to set which to use
  (default stays on `wkhtmltopdf`)


## v0.38.0

*Jul 09, 2022*

- Allow to skip login page if a single OIDC provider is configured (#1640)
- Add config to force OCR on a PDF even if text would be available (#1628)
- Improvements for OIDC integration (#1619, #1545)
- Improve unzipping/zipping files (#1603)
- Fix starting a background task to install addon (#1601)
- Add more database indexes to improve search (#1584)
- Add paging to the share view (#1582)
- Remove unused code (#1581)

### Rest API Changes

- remove `inReplyTo` from item metadata, it has never been used

### Configuration Changes

Restserver:
- Add (optional) `logout-url` to a open-id provider config block
- Add `oidc-auto-redirect`

Joex:
- Allow values <= 0 for `pdf.min-text-len` to force OCR on a pdf


## v0.37.0

*Jun 04, 2022*

- Fix e-mail address input field (#1565)
- Overhaul of search when fulltext search is applied. Fixes #1363.
- Return when a search exceeds server configured limit for page size (#1358)
- Several fixes related to addons (#1566, 1573)

### Rest API Changes

- removed `searchIndex` endpoint, because it is redundant

### Configuration Changes

- None.


## v0.36.0

*May 22, 2022*

- Extend docspell via addons (experimental feature) (#1550)
- Adds Lithuanian and Polish to document languages (#1540, #1345)
- Added a quick guide for adding more languages (#942)
- Make dashboard boxes headlines bold (#1531)
- Improve logging config; allow to specify loggers and their level (#1535)
- Allow for auth tokens to optionally be issued with an validity (#1533, 1534)
- Allow to repair db migrations, necessary for rare cases like #1517

### Rest API Changes

- new endpoints for managing addons
- new endpoint for joex to return its addon executor config

### Configuration Changes

- logging config sections allows to specfiy a map of logger names ->
  level pairs (joex and restserver)
- addon config section in restserver: allows to enable/disable
  corresponding endpoints
- addon config section in joex: allows to configure how to run addons


## v0.35.0

*Apr 14, 2022*

- Download multiple documents as zip (#1093). The webui allows to
  download multiple files as a zip archive. The zip file is created at
  the server and cached for a while.
- New project [ds4e](https://github.com/docspell/ds4e) providing some
  utilises to access Docspell from Emacs.
- Increase size for password fields in the database (#1508)
- Hide the delete button in new notifciation channel forms (#1506)
- Fix logging (#1468), non-errors were logged as errors. 
- Apply the migration fix from last version only from 0.32.0 onwards
  (#1469)
- Fix typos in UI (#1510, @monnypython)
- Add support for Postgres FTS in nix module (#1512, @LeSuisse)

### Rest API Changes

- adds routes to create and download multiple files

### Configuration Changes

- restserver: add limits for creating zip files from search queries
- joex: settings for new cleanup task that removes zip files that
  exceed some configured age


## v0.34.0

*Mar 31, 2022*

- French translation (#1440): The UI is now available in French!
  Thanks to @jgirardet.
- Link Items (#528): Link items together directly (without using
  custom fields) and see all related items quickly on the search page.
- Import mails recursively (#1260): The scanmailbox task can now go
  through folders recursively. Thanks to @Moerfi666 and @seijikun.
- Fulltext search via PostgreSQL (#424): Another backend for full-text
  search was added that is backed by PostgreSQL's text search feature.
  You can now choose between SOLR and PostgreSQL for fulltext search.
- More file backends (#1379): Next to storing the files in the
  database, you can now choose to store them in a S3 compatible
  storage or use the filesystem directly.
- Flat zip upload (#1366): An option has been added to the upload
  metadata that will unpack zip files and process each entry
  separately (instead of treating a zip file as a single item).
- Fix to upload large files (#1339): Uploaded files are not loaded
  entirely into memory allowing to upload large files.
- Fix previously published db migration (#1454, #1436): Unfortunately,
  there was an db migration in the last release that caused problems
  on some installations. A fix for this migration has been added.
- Fix build to run on windows (#1449, #1461): Building docspell on
  windows has been improved by @arittner.

For some of the new features, you need the new version of
[dsc](https://github.com/docspell/dsc).

### Rest API Changes

- adds routes to clone file repositories and the integrity check
- adds routes to support linking items
- `ScanMailboxSettings` has a new flag `scanRecursively`
- `ItemDetail` and `ItemLight` contain a new field to transport
  related/linked items
- `ItemUploadMeta` has a new flag to specify whether zip files should
  be treated as a container only, and be "flattened" into the list of
  uploaded files

### Configuration Changes

- rest server only: added options to tune the http server
- joex only: adds a file integrity check to the regular house keeping tasks
- configuration for postgresql based full-text search
- extend `files` config adding the different storage backends for
  files


## v0.33.0

*Mar 6, 2022*

- Refactor file identifiers, as preparation for different file storage
  backends (#1380)
  - **PLEASE NOTE** this release contains a DB migration that changes
    all file identifiers in the database. It is really very much
    recommended to do a backup of the database *before* updating!
- Allow background tasks to return results that are published via events (#1362)
  - the task for processing files returns now data (item id, name,
    extracted text, tags etc) that is included in the `JobDone` event
    data
- Users can specify a time zone in user settings (#1062)
  - the time zone is used when formatting dates in the web ui
  - the time zone is used for calendar events of periodic tasks; you
    need to save each periodic task again in order to pass a different
    timezone
  - should you have calendar events in the config file, you can add a
    time zone at the end
  - if not specified, it will default to UTC as before
- Improve item selection (#1422)
  - selecting items was possible before, but only ephemeral in the list view
  - it is now stored globally and kept until you explicitely clear the selection
  - items can be selected in detail view and the search menu shows an
    entry to quickly see all items currently selected
  - makes it easier to select a bunch of documents for sharing/bookmarking etc
- Change logging format and backend
  - The logging format has changed again from logfmt to the "classic" one
  - the configuration allows to use logfmt, json or two "classic" formats
  - logback has been removed! If you used a custom `logback.xml`
    before, I'm sorry this is not possible anymore. There are two
    settings in the config file for now to control logging:
    `logging.minimum-level` and `logging.format`.
- Pdf preview not updated (#1210)
  - some browsers (e.g. safari and some mobile browsers) don't update
    the ui when the `src` attribute of the `embed` element changes
  - for the "fallback view", an `iframe` is now used - thus for mobile
    it should work now. Safari on desktop would require to change the
    respective setting
- Several ui improvements
  - More cards per row for large screens (#1401)
  - more space below direction dropdown (#1400)
  - fix input field save-while-typing (#1340, #1299)
  - improves detail view on small screens (#1420)
  - sort tags by group and then name (#1396)
  - fix bug presenting an empty tag category in search menu (#1402)
  - wrap long text in dashboard tables (#1357)
  - typo fixes (#1387, #1433)
- Remove tools package from release (#1421)
  - the tools package doesn't contain general useful stuff anymore and
    is thus removed from the release packaging. The code is still
    there, and can be packaged manually

### Rest API Changes

None.

### Configuration Changes

- add `logging.format` and `logging.minimum-level`
- change default values for calendar events to explicitely show that
  they are in UTC (the value itself is not changed)


## v0.32.0

*Feb 06, 2022*

- Dashboards: There is a new starting page showing a dashboard.
  Dashboards can be customized (#1294)
- UI-settings can be specified per collective and then be overriden by
  user settings (#838)
- Managing notifications channels: Instead of giving channel data with
  each notification hook, they can now be managed separately. This is
  more convenient, because they can be reused for different
  notification hooks and periodic queries. Notifications can be
  associated to multiple channels. (#1293)
  - Please note that some (small) manual effort is recommended when
    upgrading: The channel data from all your current notifications is
    copied into a separate data set. This can create duplicates if you
    had notifications with equal channel data. In order to remove
    these duplicates, first change all notifications to a known
    channel and afterwards you can delete the obsolete ones.
- Replace bundled pdf viewer with pdfjs default viewer. (#1304)
- Fixes the query used in a periodic query, that had returned trashed
  items (#1323)
- Fixes UI bugs where some data was not initialized in the view
  (#1324)
- Fix sorting tags in search menu (#1318)
- Reworked website using tailwindcss

## v0.31.0

*Jan 16, 2022*

- Bookmark queries and use it in searches. (#1175) Also the periodic
  query form is updated to allow using a bookmarks.
- Customize message for periodic queries (#1258). You can now add your
  own sentence to the beginning of the message notifying you for a
  list of items.
- Allow to configure a priority for Gotify notifications (#1277)
- Improve handling tags (#960). When choosing a tag by the dropdown
  the catgory is shown next to a tag and the options can be
  constrainted by clicking a category bubble.
- Fix timezone in docker image (#1234)
- Fix adding high-dpi images that would cause an out-of-memory error
  when generating previews (#1183).
- Fix tearing down and initializing pubsub table to allow changing app
  ids (#1251)
- Fix switching between tile and list view when "full width" preview
  is enabled (#1261)
- Disable "group by month" if there are no groups (#1255)
- Fix deleting periodic queries (button was not working) (#1257)

### Rest API Changes

- new routes for managing bookmarks
- added routes for client settings to be separated between user and
  collective, the previous endpoint now returns a merged json
- add a priority value to gotify settings
- add bookmark value to periodic query settings

### Configuration Changes

None.


## v0.30.1

*Dec 22, 2021*

Bug fix release for #1229: notification mails could not be sent. 


## v0.30.0

*Dec 21, 2021*

- Add a list view for items, allowing to toggle between tile and list
  view (#526)
- Generic notification system: It is a start. A few events are
  available with the idea to add more when needed. Get notified about
  certain events via gotify, matrix or e-mail. A generic periodic
  query has been added (in addition to the notify-due-items task).
  (#848, #1174)
- Update stanford-corenlp and add Spanish to the supported language
  set for NLP and Hungarian to the standard set of languages.
- Fix to update job execution count when a job is canceled (#1182)
- Change the log format to [logfmt](https://www.brandur.org/logfmt)
  and remove all ansi color sequences

### Rest API Changes

- added new routes to manage notification channels and hooks
- added new routes for the generic periodic query task

### Configuration Changes

None.


## v0.29.0

*Nov 18, 2021*

- Show number of waiting jobs in the top bar (#1069). This introduces
  some changes under the hood, for example: while previously the
  restserver was notifying job executors about new jobs, it will now
  also *receive* messages from the job executors. This requires a new
  setting (see below).
- Hide sidebar by default on mobile (#1169)
- Improve scanmailbox form (#1147)
- Improve input of an e-mail address (#987)
- Fix e-mail import for certain files (#1140)
- Fix uploading files with non-ascii filenames (#991)

### Rest API Changes

None

### Configuration Changes

**Important**

- the restserver has a new setting `internal-url` which must be set to
  the base url of the server such that other nodes (i.e. joex nodes)
  can reach it. It is by default set to `http://localhost:7880`. If
  you are using docker: the `docker-compose.yml` in this repository
  has been updated. You can copy&paste the new env variable
  `DOCSPELL_SERVER_INTERNAL__URL=http://docspell-restserver:7880` into
  your `docker-compose.yml` or add it to your config file.


## v0.28.0

*Oct 27, 2021*

- Share items (#446). Allows to create shares, public cryptic links,
  to a subset of your documents that can be shared with other people
  (who don't need an account). It is possible to search inside the
  shared subset. Shares have a lifetime and can be password protected.
- Support encrypted PDFs (#1074). When importing PDF files, the
  protection layer (usually for signed PDFs) is being removed in order
  to process it. The config file and collective settings can now
  define a list of passwords that are being used when trying to
  decrypt encrypted PDFs.
- Use environment variables to configure Docspell instead of a config
  file (#1121). This is mainly intended when running via docker or
  other similar tools. Note that settings that accept list as its
  values are not yet supported.
- Try to detect the best way to render PDFs (#1099). Mobile browsers
  need a fallback for rendering PDFs, but desktop browsers can do it
  much better natively. The user settings allow to decide how to
  render a PDF or to let docspell detect it.
- Filter possible values in search menu based on current results
  (#856). This removes options that would only yield empty results
  from the dropdowns.
- Fix search in documenation (#1120)

### Rest API Changes

- `/share/*` routes to access a share
- `/open/share/verify` routes to verify a share id
- `/sec/share/*` routes to manage shares
- extend `SearchStats` to include correspondents/concerning numbers

### Configuration Changes

- restserver: changed the server secret from the (dummy) value
  `hex:caffee` to an empty string. This results in a random secret
  generated at application start. It is recommended to set it to some
  random value, otherwise sessions don't survive server restarts.
- joex: adds a section `decrypt-pdf` for specifying a list of
  passwords to try when encountering encrypted PDFs
  

## v0.27.0

*Sep 23, 2021*

- Allow external authentication providers via [OpenID
  Connect](https://openid.net/connect). Now you can integrate Docspell
  into your SSO solution. Using keycloak, for example (or other such
  tools) users can be maintained elsewhere, like in an LDAP directory.
  (#489)
- Adds two-factor authentication using TOTPs. If you don't want to
  setup an external authentication provider (which is another tool to
  maintain), you can use the builtin TOTP support to have two-factor
  authentication. (#762)
- Improvements when querying documents (#1040)
- Changed the underlying code for storing and loading files. This is a
  preparation to allow different storage backends for files in the
  future (maybe the filesystem or s3). (#1080)
- The license has changed from GPLv3+ to AGPLv3+ (#1078)
- Fixes a bug in the "check for updates" task that was added in the
  last release (#1068)
- Reduces the length of the startup command, which makes tools like
  `ps` much more readable and allows now to start docspell on Windows
  (untested, though ;-)) (#1062)
- Fixes merging items, where sent mails were not copied to the target
  item. (#1055)
- Fixes and improves deleting users. Now all their data is also
  removed and it is shown what that would be. (#1060)

### Rest API Changes

- The `login` routes now won't return a session token when 2FA is
  enabled for an account. The returned token must be used to provide
  the TOTP in order to finalize login.
- Added `open/auth/two-factor` endpoint to provide the TOTP for login
- Added `open/auth/openid/{providerId}[/resume]` endpoints to initiate
  authentication via an external provider
- Added `sec/user/{username}/deleteData` to retrieve a summary of data
  that would be deleted with that user
- Added `sec/user/otp/*` endpoints to manage the TOTP for an account
- Added `admin/user/otp/reserOTP` to reset the 2FA setup for any user

### Configuration Changes

- Restserver: Added a section to configure external authentication
  provider


## v0.26.0

*Aug 28, 2021*

- Add ability to merge items (#414). You can now select multiple items
  and merge them all into one. The first item in the list is the
  target item, all others are deleted after a successful merge. The
  webapp allows to reorder this list, of course.
- Add option to only import attachments of e-mails (#983). 
- Improve *Manage Data* page by sorting the tables (#965, #538)
- Allow wildcard searches in queries using `attach.id` (#971). Before
  you would have to specify the complete id. This is inconvenient when
  using from the command line client.
- Add Hebrew to the document languages (#1027, thans @wallace11).
  Please note, that the SOLR support is very basic for this language.
- Add a periodic task to check for Docspell updates (#990). Let's you
  check periodically for new versions of docspell. It uses an existing
  user account and its mail settings to send an e-mail.
- Show the link to an item and its attachments as a QR code in item
  details (#836). This might be useful when you want to attach this
  link to physical devices.
- The search menu highlights the sections that contain active filters
  (#966)
- Safe deletion of items (#347). When deleting items, they are now
  *marked as deleted* and can therefore be restored. A periodic job
  will really delete them from the database eventually.
- Improves German translation (#985, thanks @monnypython)
- The [dsc](https://github.com/docspell/dsc) tool has also been
  improved, thanks to @seijikun.
- Upgrade the website to work with newer zola versions (#847)
- Remove the scripts in `tools/` since these are now obsolete. The new
  [command line interface](https://github.com/docspell/dsc) covers
  these features now. Note that the docker images are also NOT built
  anymore. The directory still exits and is still a place for scripts
  and little tooling around docspell.
- Fixes a regression where the browser would not display the pdf (#975)
- Fixes the health checks in the docker setup (#976)
- Fixes an issue with text extraction for Japanese documents where
  numbers were extracted as special unicode points (#973). This only
  affects the docker setup, when not using the docker images you need
  to setup tesseract to use different training data for Japanese.

### Rest API Changes

Complete
[diff](https://github.com/eikek/docspell/compare/v0.25.1...master#diff-5dfb63e478c5511c16420f5e4d139666603d1c625546af06c4de50d0ae64a94f)
(need to click the *Files changed* tab)

- The routes to fetch a list of tags, organizations, persons, fields
  etc can now optionally take a `sort` query parameter to specify how
  to order the list.
- Added `/sec/collective/emptytrash/startonce` to run the task to
  empty the trash immediately
- The search endpoints can now take an optional parameter `searchMode`
  that defines whether to search in trashed items or not
- Deleting an item via the api now only changes its state to *Trashed* 
- Added `/sec/item/{id}/restore` to restore a trashed item (unless it
  has been deleted from the database).
- Added `/sec/items/restoreAll` to restore multiple of trashed items
- Added `/sec/items/merge` that accepts a POST request with a list of
  items to merge. The first item is the "target" item. All other items
  are deleted after the merge was successful.
- The `ScanMailboxSettings`, `Source` and `ItemUploadMeta` structures
  now contains a boolean field `attachmentsOnly`
- `ItemInsights` structure now contains a counter for trashed items
- `CollectiveSettings` structure now has a section to specify settings
  for periodically deleting trashed items.

### Configuration Changes

- Joex: A new section for configuring the update task has been added.
  See section `update-check` in the default [config
  file](https://docspell.org/docs/configure/defaults/#joex).


## v0.25.1

*Jul 29, 2021*

- Fix solr fulltext search by adding the new japanese content field

The SOLR fulltext search is broken in 0.25.0, so this is a fixup
release.

## v0.25.0

*Jul 29, 2021*

- Introducing a new CLI tool (#345) that replaces all the shell
  scripts from the `tools/` directory! https://github.com/docspell/dsc
- UI changes:
  - year separators are now more prominent (#950)
  - fixes a bug in the item counter in detail view when an item is
    deleted (#920)
  - German translation improvements (#901)
  - The number of selected files is shown in upload page (#896)
- The created date of an item can now be used in queries (#925, #958)
- Setting tags api has been improved (#955)
- Task for converting pdfs is now behind the admin secret (#949)
- Task for generating preview images is now behind the admin secret (#915)
- respond with 404 when the source-id is not correct (#931)
- Update of core libraries (#890)
- Add Japanese to the list of document languages. Thanks @wallace11
  for helping out (#948, #962)
- Fix setting the folder from metadata when processing a file and
  allow to specifiy it by name or id (#940)
- Fixes docspell config file in docker-compose setup (#909)
- Fixes selecting the next job in the job executor (#898)
- Fixes a bug that prevents uploading more than one file at once
  (#938)

### Rest API Changes

- Removed `sec/item/convertallpdfs` endpoint in favor for new
  `admin/attachments/convertallpdfs` endpoint which is now an admin
  task
- Removed `sec/collective/previews` endpoint, in favor for new
  `admin/attachments/generatePreviews` endpoint which is now an admin
  task to generate previews for all files. The now removed enpoint did
  this only for one collective.
- `/sec/item/{id}/tags`: Setting tags to an item (replacing existing
  tags) has been changed to allow tags to be specified as names or ids
- `/sec/item/{id}/tagsremove`: Added a route to remove tags for a
  single item
  
### Configuration Changes

None.


## v0.24.0

*Jun 18, 2021*

This time a translation of the Web-UI in German is included and the
docker build was overhauled. The releases are now build and tested
using Java 11.

- Rework Docker setup. Images are now provided for different
  architectures and have a new home now (see below). The images are
  now built via a github-action from the official packages of each
  release. (#635, #643, #840, #687)
- Translation of the UI into German (thanks to @monnypython for proof
  reading and applying lots of corrections!) (#292, #683, #870)
- Improve migration of SOLR (#604)
  - The information whether solr has been setup, is now stored inside
    SOLR. This means when upgrading Docspell, all data will be
    re-indexed.
- Add `--exclude` and `--include` options to the `consumedir.sh`
  script (#885)
- Improved documenation of the http api (#874)
- Removed unused libraries in the final packages to reduce file size a
  bit (#841)
- Bug: Searching by tag category was broken when using upper case
  letters (#849)
- Bug: when adding a boolean custom field, it must be applied
  immediatly (#842)
- Bug: when entering a space in a dropdown the menu closes (#863)
- Bug: Some scripts didn't work with earlier versions of `jq` (#851)
- Bug: The source form was broken in that it didn't load the language
  correctly (#877)
- Bug: Tag category options were wrongly populated when narrowing tags
  via a search (#880)

### Breaking Changes

#### Java 11

Not really a breaking change. Docspell is now build and tested using
Java 11. Docspell has a small amount of Java source code. This is
compiled using Java 11 but to target Java 8 JVMs. So it still can run
under Java 8. However, it is recommended to use at least Java 11 to
run Docspell.


#### Docker Images

The docker images are now pushed to the
[docspell](https://hub.docker.com/u/docspell) organization at
docker-hub! So the images are now:

- `docspell/restserver`
- `docspell/joex`
- `docspell/tools`

Tags: images are tagged with two floating tags: `nightly` and
`latest`. The `nightly` tag always points to the latest development
state (the master branch). The `latest` tag points to the latest
release. Each release is also tagged with its version number, like
`v0.24.0`.

The images changed slightly in that there is no assumption on where
the config file is placed. Now you need to pass the docspell config
file explicitely when using the images.

Multiarch: Images are now build for `amd64`, `arm64` and `armv7`.

The consumedir is being replaced by the more generic `docspell/tools`
image which contains all the scripts from the `tools/` section. That
means it has no special entrypoint for the consumedir script anymore.
The polling functionality is now provided by the consumedir script.
And the docker-compose file needs now to specify the complete command
arguments. This makes it much more flexible to use.

This allows to use this image to run all the other tool scripts, too.
The scripts are in PATH inside the image and prefixed by `ds-`, so for
example `ds-consumedir` or `ds-export-files` etc.

#### Docker Compose

The docker-compose setup is now at `docker/docker-compose`. Please
look at the new [compose
file](https://github.com/eikek/docspell/blob/master/docker/docker-compose/docker-compose.yml)
and do the corresponding changes at yours. Especially the consumedir
container changed significantly. Then due to the fact that the config
file must be given explicitely, you need to add this argument to each
docspell component (restserver and joex) via a `command` section (see
the compose file referenced above).

The `.envrc` has been cleaned from some settings. Since the config
files is mounted into the image, you can just edit this file instead.
The only settings left in the .envrc file are those that need to be
available in the docker-compose file and the application. If some
settings need to be duplicated for joex and restserver, you can use
the builtin variable resolution mechanism for this. An example is
provided in the new config file.

### Configuration Changes

None.


### Rest API Changes

None.


## v0.23.0

*May 29, 2021*

This release enables deleting multiple files at once of an item. It
also changes how user settings are stored. Additionally several bugs
in the ui and server have been fixed.

- Feature: Central user settings (#565): user settings have been
  stored in the browser but are now stored at the server. This means
  that all settings are now shared across all devices. See below for
  notes on migrating your current settings.
- Feature: Delete multiple attachemnts at once, thanks to
  @stefan-scheidewig (#626): multiple attachments on an item can be
  deleted with a single click
- Feature: Make consumedir-cleaner run on windows, thanks to
  @JaCoB1123 (#809)
- Bug: More work externalizing strings (#784, #760): many more strings
  have been externalized for being translated; also dates are now
  externalized, too
- Bug: Better anonymous upload page (#758): the upload page for
  anonymous users shouldn't show a form to provide any metadata
- Bug: Tag category color (#835): the input field to specify colors
  for tag categories didn't show the category name
- Bug: Search in names (#822): a bug in the webui sent a broken query
  to the server, making the "search in names" field unusable
- Bug: Fulltext only search broken (#823): the fulltext only search
  didn't only consult the solr index, but also the database, making it
  a lot slower and presenting the results not in the order returned by
  solr.
- Bug: Ui switches to logged in state on auth failure (#814)
- Bug: Broken search summary when tag has no category (#759)


### Migrating UI Settings

After the upgrade to this version, your current ui settings are not
read anymore. That means docspell starts up with a light theme and tag
colors are gone etc. If there are no settings at the server, but
docspell finds some at your browser, the *UI Settings* page shows a
big message and a button. Clicking this button sends your settings to
the server. This message disappears as soon as there are some settings
on the server.

If you have multiple devices, you now need to choose one which
settings you want to migrate to the server. It is currently not
possible to store settings per device.

***Note**: the button is only there if there are no settings at the
server. So if you want to migrate, don't set the theme or click on
other things that are persisted before doing the migration!*

### REST Api Changes

- new routes have been added to delete multiple attachments of an item
- new routes have been added to manage client settings

### Configuration Changes

- none


## v0.22.0

*Apr 11, 2021*

This release fixes some annoying bugs and prepares the web-ui to be
translated into other languages. For actual translating them, I ask
for your help. There is a detailed post about how to start with it [in
the docs](https://docspell.org/docs/dev/translation/).

- Refactor webui to prepare for localisation (#726)
- Add names to user defined tasks for better documentation (#712)
- Fixes some ui bugs:
  - scrollbar position (#722)
  - other minor ui related fixes (#746)
- Removed deprecated api endpoints, fixing #482
- Fixes bug where items are already shown in the ui, although still in
  processing (#719)
- Switch to github actions for ci (#748)
- Fixes a bug in the new query language (#754)
- Fix counters for categories in the search menu (#755)

### REST Api Changes

- remove deprecated endpoints: `sec/item/searchForm`,
  `sec/item/searchFormWithTags`, `sec/item/searchFormStats`
- adds category-count data to `SearchSummary`

### Configuration Changes

- none


## v0.21.0

*Mar 13, 2021*

The main feature of this release gives a very flexible way of
searching for documents, using a query.

- Add a query language to provide a flexible way for searching
  - the search form now is translated into a search query
  - allows to search for items not in a folder or not in a specific
    folder (#628, #379)
  - Allows for range searches in custom fields (#540)
  - And more! See [the
    documentation](https://docspell.org/docs/query/)
- Add a `use` attribute to all metadata, to be able to exclude them
  from suggestions (#659)
- Allow to submit items for reprocessing via the UI (#365)
- Add Latvian language (#679)
- Scrollbars are back! (#681, #677)
- The `ds.sh` script was changed to inform the processing jobs to also
  check for duplicates (#653)
- Docker setup now uses again a fixed hostname (#608)
- Moving the unit tests to MUnit (#672)
- Remove the old UI code (#636)
- Fix date extraction for English (#665)
- Fix bug when reading contacts from extracted text (#709)
- Fix bugs when reading mails (#691, #678)
- Fix a bug that wouldn't show an error message when entering bad
  characters in the register form (#663)
- Fixes a typo in the user settings menu (#654, thanks
  @ChristianKlass)

Thanks to everyone showing interest in docspell and dedicating time by
opening issues, testing and providing ideas!

### REST Api Changes

*Note there are breaking changes in the REST Api*

- previous `search` and `searchWithTags` has been renamed to
  `searchForm` and `searchFormWithTags`, respectively
- same with `searchStats`, it has been renamed to `searchFormStats`
- The new `search` route can be used with `GET` and `POST` requests
  and accepts now a search query and also a flag for whether returning
  details or not (there are no separate endpoints anymore)
- The new `searchStats` accepts a query
- The `ItemQuery` data structure is now only a query string, without
  `limit` and `offset`
- `Organization` and `Person` have an additional `use` attribute

### Configuration Changes

There were no changes to the configuration files.


## v0.20.0

*Feb 19, 2021*

This release comes with a completely new ui based on
[tailwindcss](https://tailwindcss.com), including a dark theme!
Additionally there are some other minor features and bug fixes.

- New Web-UI with light and dark theme (#293).
  - All markup and css was reworked. For this release, the old ui is
    still available as a fallback if something got missing while
    porting. The old ui will be removed in the next release.
  - Experience on mobile devices is greatly improved
  - to get back to the old ui, you need to install a browser extension
    to be able to add a request header. Check [this for
    firefox](https://addons.mozilla.org/en-US/firefox/addon/modheader-firefox/)
    or [this for
    chromium](https://chromewebstore.google.com/detail/modheader-modify-http-hea/idgpnmonknjnojddfkpgkljpfnnfcklj)
  - then add the request header `Docspell-Ui` with value `1`.
    Reloading the page gets you back the old ui.
- With new Web-UI, certain features and fixes were realized, but not
  backported to the old ui:
  - foldable sections in search and multi-edit menu (#613, #527)
  - show current item in detail view (#369)
  - fixed some ui issues regarding processing logs (#363)
  - scrollbar fix (#600)
- Allow a person to be correspondent, concerning or both (#605)
- Add a short-name field to the organization (#560)
- Add a description field to the equipment (#633)
- Allow to specify a language for a source url (#651). This can be
  used to define upload urls per document language.
- Trim whitespace for certain fields (#539)
- A different docker entrypoint for the consumedir script was added
  that supports polling (thanks @JaCoB1123, #603, #624)
- Fix duplicate suggestions (#627)
- Fix reading mails with empty headers (#606)
- Fix suggesting person that doesn't belong to the suggested
  organization (#625)
- Cleanup registered nodes periodically (#618)

### REST Api Changes

- The `Person` structure was changed: the `concerning` boolean flag is
  replaced by a `use` attribute
- The `Equipment` structure has an additional `notes` attribute
- The `Source` structure has an additional `language` attribute

### Configuration Changes

- joex: 
  - additional section in `house-keeping` to configure the periodic
    node cleanup task


## v0.19.0

*Jan 25, 2021*

This release comes with major improvements to the text analysis
module. It is now much more configurable, has improved results and can
learn tags from all categories. Additionally, more languages for
document processing have been added and it's now easier to add more.
Please open an issue if want more languages to be included.

- text analysis improvements (#263, #570)
  - docspell can now learn from all your tag categories
  - the detection for correspondents/concerned entities has been
    improved by using the classifier for this, too
  - all text analysis steps are now configurable that makes it
    possible to adapt it better to your data and machine. 
  - The docs have been updated with some details
    [here](https://docspell.org/docs/configure/file-processing/) and
    [here](https://docspell.org/docs/joex/file-processing/#text-analysis).
- more languages (#488)
  - Adds: Spanish, Italian, Portuguese, Czech, Dutch, Danish, Finnish,
    Norwegian, Swedish, Russian, Romanian
  - languages have different support for text-analysis, but there is
    some basic support for all
  - there is extended support for English, German and French through
    [Stanford CoreNLP](https://stanfordnlp.github.io/CoreNLP/) nlp
    models (as before)
- scan mailbox change (#576)
  - The change from last version (#551) has been moved behind a flag
    in the "scan mailbox settings". Please review your scan mailbox
    tasks in your user settings.
  - The scan mailbox settings form view has been organized into tabs,
    as it grew too large for a single form.
- nix tools package fixed (#584)
  - If you are using docspell tools package for nix, it has now been
    fixed in that all scripts are available. They are now all prefixed
    by `ds-` (except the `ds` script)
- fix deleting organization (#578)
  - Due to the new relationship of a person to an organization,
    deleting an organization whith references a person was not
    possible. This is now fixed.
- base url fix (#579)
  - The `baseurl` setting is optional, but when specified it was
    required to omit a trailing slash. This is now fixed in that it is
    always rendered without the trailing slash to the client, no
    matter what is in the config
- tag category case sensitive search fix (#568)
  - This was a bug introduced by the last release. When tag categories
    can now be spelled upper- or lower-case. In 0.18.0 you had to
    spell them lowercase, otherwise the search doesn't work.
- adds a workaround for mails that don't specify their used charset (#591)

### Breaking Changes

- The joex configuration changed around text analysis. If you had some
  custom settings there, please review these wrt the new default
  config.
- When using the nix package manager: the tools package renamed the
  scripts to be better distinguishable, since they all end up in
  `$PATH`. They are now prefixed by `ds-`.
- The path of the consumedir script changed in the consumedir docker
  image
- The settings of the scan-mailbox task has been extended by another
  flag. It controls when to apply the post-processing (moving or
  deleting). If you were relying that all mails (even those excluded
  by a subject filter) where moved away, you need to check your
  scan-mailbox task settings.

### REST Api Changes

- the data structure for `ClassifierSettings` changed to allow
  specfiying a blacklist or whitelist of tag categories and the
  `enabled` flag has been removed.


### Configuration Changes

- joex
  - the config regarding text analysis changed, there are new config
    options, like `nlp.mode` and the `max-due-date-years` has been
    moved inside `text-anlysis`. Please have a look at the new
    [default config](https://docspell.org/docs/configure/defaults/#joex)
    if you changed something there.
  - The `regex-ner` section has changed: the `enabled` flag has been
    removed, you can now limit the number of entries using
    `max-entries` to apply and `0` means to disable it.


## v0.18.0

*Jan 11, 2021*

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
  [docs](https://docspell.org/docs/tools/cli/#admin-commands))
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
  [route](https://docspell.org/openapi/docspell-openapi.html#operation/sec-item-start-reprocess)
  has been added that submits files for re-processing. It is possible
  to re-process some files of an item or all. There is no UI for this
  for now. You'd need to run `curl` or something manually to trigger
  it. It will replace all extracted metadata of the *files*,but
  doesn't touch the metadata of the item. (#206)
- Add a task to convert all pdfs using the
  [OCRMyPdf](https://github.com/jbarlow83/OCRmyPDF) tool that can be
  used in docspell since the last release. This task converts all your
  existing PDFs into a PDF/A type pdf including the OCR-ed text layer.
  There is no UI to trigger this task, but a script is provided to
  help with it. (#206)
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
  [Solr](https://solr.apache.org) instance. Items can be searched by
  documents contents and item/file names. It is possible to use
  full-text search to further confine the results via the search menu.
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
