+++
title = "Regenerate Preview Images"
description = "Re-generates all preview images."
weight = 80
+++

# regenerate-previews.sh

This is a simple bash script to trigger the endpoint that submits task
for generating preview images of your files. This is usually not
needed, but should you change the `preview.dpi` setting in joex'
config file, you need to regenerate the images to have any effect.

# Requirements

It is a bash script that additionally needs
[curl](https://curl.haxx.se/) and
[jq](https://stedolan.github.io/jq/).

# Usage

```
./regenerate-previews.sh [docspell-base-url]
```

For example, if docspell is at `http://localhost:7880`:

```
./convert-all-pdfs.sh http://localhost:7880
```

The script asks for your account name and password. It then logs in
and triggers the said endpoint. After this you should see a few tasks
running.

There will be one task per file to convert. All these tasks are
submitted with a low priority. So files uploaded through the webapp or
a [source](@/docs/webapp/uploading.md#anonymous-upload) with a high
priority, will be preferred as [configured in the job
executor](@/docs/joex/intro.md#scheduler-config). This is to not
disturb normal processing when many conversion tasks are being
executed.
