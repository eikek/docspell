+++
title = "Convert All PDFs"
description = "Convert all PDF files using OcrMyPdf."
weight = 60
+++

# convert-all-pdf.sh

With version 0.9.0 there was support added for another external tool,
[OCRMyPdf](https://github.com/jbarlow83/OCRmyPDF), that can convert
PDF files such that they contain the OCR-ed text layer. This tool is
optional and can be disabled.

In order to convert all previously processed files with this tool,
there is an
[endpoint](/openapi/docspell-openapi.html#api-Item-secItemConvertallpdfsPost)
that submits a task to convert all PDF files not already converted for
your collective.

There is no UI part to trigger this route, so you need to use curl or
the script `convert-all-pdfs.sh` in the `tools/` directory.


# Usage

```
./convert-all-pdfs.sh [docspell-base-url]
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
executor](@/docs/joex/_index.md#scheduler-config). This is to not
disturb normal processing when many conversion tasks are being
executed.
