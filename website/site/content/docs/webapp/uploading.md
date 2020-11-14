+++
title = "Uploads"
weight = 0
+++

This page describes, how files can get into docspell. Technically,
there is just one way: via http multipart/form-data requests.


# Authenticated Upload

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

# Anonymous Upload

It is also possible to upload files without authentication. This
should make tools that interact with docspell much easier to write.
The [Android Client App](@/docs/tools/android.md) uses these urls to
upload files.

Go to "Collective Settings" and then to the "Source" tab. A *Source*
identifies an endpoint where files can be uploaded anonymously.
Creating a new source creates a long unique id which is part of an url
that can be used to upload files. You can choose any time to
deactivate or delete the source at which point uploading is not
possible anymore. The idea is to give this URL away safely. You can
delete it any time and no passwords or secrets are visible, even your
username is not visible.

Example screenshot:

{{ figure(file="sources-edit.png") }}

This example shows a source with name "test". Besides a description
and a name that is only used for displaying purposes, a priority and a
[folder](@/docs/webapp/metadata.md#folders) can be specified.

The priority is used for the processing jobs that are submitted when
files are uploaded via this endpoint.

The folder is used to place all items, that result from uploads to
this endpoint, into this folder.

The source endpoint defines two urls:

- `/app/upload/<id>`
- `/api/v1/open/upload/item/<id>`

{{ figure(file="sources-form.png") }}

The first points to a web page where everyone could upload files into
your account. You could give this url to people for sending files
directly into your docspell.

The second url is the API url, which accepts the requests to upload
files. This second url can be used with the [Android Client
App](@/docs/tools/android.md) to upload files.

Another example is to use curl for uploading files from the command
line::

``` bash
$ curl -XPOST -F file=@test.pdf http://192.168.1.95:7880/api/v1/open/upload/item/3H7hvJcDJuk-NrAW4zxsdfj-K6TMPyb6BGP-xKptVxUdqWa
{"success":true,"message":"Files submitted."}
```

There is a [script provided](@/docs/tools/ds.md) that uses curl to
upload files from the command line more conveniently.

When files are uploaded to an source endpoint, the items resulting
from this uploads are marked with the name of the source. So you know
which source an item originated. There is also a counter incremented
for each reqest.

If files are uploaded using the web applications *Upload files* page,
the source is implicitly set to `webapp`. If you also want to let
docspell count the files uploaded through the web interface, just
create a source (can be inactive) with that name (`webapp`).


# Other options

More details about the actual http request and other upload options
can be found [here](@/docs/api/upload.md).
