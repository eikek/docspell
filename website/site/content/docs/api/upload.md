+++
title = "Upload Request"
description = "Describes the upload request"
weight = 20
insert_anchor_links = "right"
+++

# Upload Request

Uploads of files to docspell are always processed the same way, no
matter if coming from a source, the integration endpoint or from the
webapp.

The request must be a http `multipart/form-data` request, with two
possible fields:

- meta
- file

The `file` field can appear multiple times and is required at least
once. It is the part containing the file to upload.

The `meta` part is optional and can define additional meta data, that
docspell applies to items created from the given files. It allows to
transfer structured information together with the unstructured binary
files.

This kind of request is very common and most programming languages
have support for this.

For example, here is a curl command uploading two files with meta
data. Since `multiple` is `false`, both files are added to one item:

``` bash
curl -XPOST -F meta='{"multiple":false, "direction": "outgoing", "tags": {"items":["Order"]}}' \
            -F file=@letter-en.pdf \
            -F file=@letter-de.pdf \
            http://192.168.1.95:7880/api/v1/open/upload/item/3H7hvJcDJuk-NrAW4zxsdfj-K6TMPyb6BGP-xKptVxUdqWa
```

# Metadata

Each upload request can specify a set of metadata that should be
applied to the item(s) that are created from this upload. This is
specified via a JSON structure in a part with name `meta`:

``` elm
{ multiple: Bool
, direction: Maybe String
, folder: Maybe String
, skipDuplicates: Maybe Bool
, tags: Maybe StringList
, fileFilter: Maybe String
, language: Maybe String
, attachmentsOnly: Maybe Bool
, flattenArchives: Maybe Bool
}
```

- The `multiple` property is by default `true`. It means that each
  file in the upload request corresponds to a single item. An upload
  with 5 files will result in 5 items created. If it is `false`, then
  docspell will create just one item, that will then contain all
  files.
- Furthermore, the direction of the document (one of `incoming` or
  `outgoing`) can be given. It is optional, it can be left out or
  `null`.
- A `folder` id can be specified. Each item created by this request
  will be placed into this folder. Errors are logged (for example, the
  folder may have been deleted before the task is executed) and the
  item is then not put into any folder.
- The `skipDuplicates` is optional and set to `false` if not
  specified. It configures the processing task. If set to `true`, the
  processing task will skip all input files that are already present
  in docspell.
- The `tags` field can be used to provide tags that should be applied
  automatically. The `StringList` is a json object containing one
  field `items` that is a list of strings:

  ``` elm
  { items: (List String)
  }
  ```

  Tags can be defined using their ids or names.
- Then a `fileFilter` field can be used to filter files from uploaded
  archives. Say you upload a zip file and want only to include certain
  files, you could give a file filter like `*.pdf` to only select pdf
  files or `*.html|*.pdf` for selecting html and pdf files. This only
  applies to archive files, like zip or e-mails (where this is applied
  to the attachments).
- The `language` is used for processing the document(s) contained in
  the request. If not specified the collective's default language is
  used.
- The `attachmentsOnly` property only applies to e-mail files (usually
  `*.eml`). If this is `true`, then the e-mail body is discarded and
  only the attachments are imported. An e-mail without any attachments
  is therefore skipped.
- `flattenArchives` is flag to control how zip files are treated. When
  this is `false` (the default), then one zip file results in one item
  and its contents are the attachments. If you rather want the
  contents to be treated as independent files, then set this to
  `true`. This will submit each entry in the zip file as a separate
  processing job. Note: when this is `true` the zip file is just a
  container and doesn't contain other useful information and therefore
  is *NOT* kept in docspell, only its contents are. Also note that
  only the uploaded zip files are extracted once (not recursively), so
  if it contains other zip files, they are treated as normal.

# Endpoints

Docspell needs to know the collective that owns the files. There are
the following ways for this.


## Authenticated User

```
/api/v1/sec/upload/item
```

This endpoint exists for authenticated users. That is, you must
provide a valid cookie or `X-Docspell-Auth` header with the request.
You can obtain this from the `login` endpoint.

## URL protected

```
/api/v1/open/upload/item/5JE…-…-…-…oHri
```

A more flexible way for uploading files is to create a
[“Source”](@/docs/webapp/uploading.md#anonymous-upload) that creates a
“hard-to-guess” url. A source can be created in the webapp (via http
calls) and associates a random id to a collective. This id is then
used in the url and docspell can use it to associate the collective
when uploading.

When defining sources, you can also add metadata to it. These will be
used as a fallback when inspecting the requests meta data part. Each
metadata not defined in the request will be filled with the one from
the corresponding source. Tags are applied from both inputs.

## Integration Endpoint

Another option for uploading files is the special *integration
endpoint*. This endpoint allows an admin to upload files to any
collective, that is known by name.

```
/api/v1/open/integration/item/[collective-name]
```

The endpoint is behind `/api/v1/open`, so this route is not protected
by an authentication token (see [REST Api](@/docs/api/_index.md) for
more information). However, it can be protected via settings in the
configuration file. The idea is that this endpoint is controlled by an
administrator and not the user of the application. The admin can
enable this endpoint and choose between some methods to protect it.
Then the administrator can upload files to any collective. This might
be useful to connect other trusted applications to docspell (that run
on the same host or network).

The endpoint is disabled by default, an admin must change the
`docspell.server.integration-endpoint.enabled` flag to `true` in the
[configuration file](@/docs/configure/main.md#rest-server).

If queried by a `GET` request, it returns whether it is enabled and
the collective exists.

It is also possible to check for existing files using their sha256
checksum with:

```
/api/v1/open/integration/checkfile/[collective-name]/[sha256-checksum]
```

See the [SMTP gateway](@/docs/tools/smtpgateway.md) or the [dsc
watch/upload](@/docs/tools/cli.md#docker) command for example can use
this endpoint.
