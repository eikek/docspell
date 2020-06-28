---
layout: docs
title: Uploads
permalink: doc/uploading
---

# {{page.title}}


This page describes, how files can get into docspell. Technically,
there is just one way: via http multipart/form-data requests.


## Authenticated Upload

From within the web application there is the "Upload Files"
page. There you can select multiple files to upload. You can also
specify whether these files should become one item or if every file is
a separate item.

When you click "Submit" the files are uploaded and stored in the
database. Then the job executor(s) are notified which immediately
start processing them.

Go to the top-right menu and click "Processing Queue" to see the
current state.

This obviously requires an authenticated user. While this is handy for
ad-hoc uploads, it is very inconvenient for automating it by custom
scripts. For this the next variant exists.

## Anonymous Upload

It is also possible to upload files without authentication. This
should make tools that interact with docspell much easier to write.


### Creating Anonymous Uploads

Go to "Collective Settings" and then to the "Source" tab. A *Source*
identifies an endpoint where files can be uploaded
anonymously. Creating a new source creates a long unique id which is
part on an url that can be used to upload files. You can choose any
time to deactivate or delete the source at which point uploading is
not possible anymore. The idea is to give this URL away safely. You
can delete it any time and no passwords or secrets are visible, even
your username is not visible.

Example screenshot:

<div class="thumbnail">
  <img src="../img/sources-form.jpg">
</div>

This example shows a source with name "test". It defines two urls:

- `/app/upload/<id>`
- `/api/v1/open/upload/item/<id>`

The first points to a web page where everyone could upload files into
your account. You could give this url to people for sending files
directly into your docspell.

The second url is the API url, which accepts the requests to upload
files (which is used by the first url).

For example, this url can be used to upload files with curl:

``` bash
$ curl -XPOST -F file=@test.pdf http://localhost:7880/api/v1/open/upload/item/CqpFTb7UmGe-9nMVPZSmnwc-AHH6nWFh52t-M1JFQ9y7cdH
{"success":true,"message":"Files submitted."}
```

You could add more `-F file=@/path/to/your/file.pdf` to upload
multiple files (note, the `@` is required by curl, so it knows that
the following is a file).

When files are uploaded to an source endpoint, the items resulting
from this uploads are marked with the name of the source. So you know
which source an item originated.

If files are uploaded using the web applications *Upload files* page,
the source is implicitly set to `webapp`. If you also want to let
docspell count the files uploaded through the web interface, just
create a source (can be inactive) with that name (`webapp`).


## Integration Endpoint

Another option for uploading files is the special *integration
endpoint*. This endpoint allows an admin to upload files to any
collective, that is known by name.

```
/api/v1/open/integration/item/[collective-name]
```

The endpoint is behind `/api/v1/open`, so this route is not protected
by an authentication token (see [REST Api](../api) for more
information). However, it can be protected via settings in the
configuration file. The idea is that this endpoint is controlled by an
administrator and not the user of the application. The admin can
enable this endpoint and choose between some methods to protect it.
Then the administrator can upload files to any collective. This might
be useful to connect other trusted applications to docspell (that run
on the same host or network).

The endpoint is disabled by default, an admin must change the
`docspell.server.integration-endpoint.enabled` flag to `true` in the
[configuration file](configure#rest-server).

If queried by a `GET` request, it returns whether it is enabled and
the collective exists.

It is also possible to check for existing files using their sha256
checksum with:

```
/api/v1/open/integration/checkfile/[collective-name]/[sha256-checksum]
```

See the [SMTP gateway](tools/smtpgateway) or the [consumedir
script](tools/consumedir) for examples to use this endpoint.

## The Request

This gives more details about the request for uploads. It is a http
`multipart/form-data` request, with two possible fields:

- meta
- file

The `file` field can appear multiple times and is required at least
once. It is the part containing the file to upload.

The `meta` part is completely optional and can define additional meta
data, that docspell uses to create items from the given files. It
allows to transfer structured information together with the
unstructured binary files.

The `meta` content must be `application/json` containing this
structure:

```
{ multiple: Bool
, direction: Maybe String
}
```

The `multiple` property is by default `true`. It means that each file
in the upload request corresponds to a single item. An upload with 5
files will result in 5 items created. If it is `false`, then docspell
will create just one item, that will then contain all files.

Furthermore, the direction of the document (one of `incoming` or
`outgoing`) can be given. It is optional, it can be left out or
`null`.

This kind of request is very common and most programming languages
have support for this. For example, here is another curl command
uploading two files with meta data:

```
curl -XPOST -F meta='{"multiple":false, "direction": "outgoing"}' \
            -F file=@letter-en-source.pdf \
            -F file=@letter-de-source.pdf \
            http://localhost:7880/api/v1/open/upload/item/CqpFTb7UmGe-9nMVPZSmnwc-AHH6nWFh52t-M1JFQ9y7cdH
```
