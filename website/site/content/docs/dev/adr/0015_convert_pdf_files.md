+++
title = "Convert PDF Files"
weight = 160
+++

# Context and Problem Statement

Some PDFs contain only images (when coming from a scanner) and
therefore one is not able to click into the pdf and select text for
copy&paste. Also it is not searchable in a PDF viewer. These are
really shortcomings that can be fixed, especially when there is
already OCR build in.

For images, this works already as tesseract is used to create the PDF
files. Tesseract creates the files with an additional text layer
containing the OCRed text.

# Considered Options

* [ocrmypdf](https://github.com/jbarlow83/OCRmyPDF) OCRmyPDF adds an
  OCR text layer to scanned PDF files, allowing them to be searched


## ocrmypdf

This is a very nice python tool, that uses tesseract to do OCR on each
page and add the extracted text as a pdf text layer to the page.
Additionally it creates PDF/A type pdfs, which are great for
archiving. This fixes exactly the things stated above.

### Integration

Docspell already has this built in for images. When converting images
to a PDF (which is done early in processing), the process creates a
text and a PDF file. Docspell then sets the text in this step and the
text extraction step skips doing its work, if there is already text
available.

It would be possible to use the `--sidecar` option with ocrmypdf to
create a text file of the extracted text with one run, too (exactly
like it works for tesseract). But for "text" pdfs, ocrmypdf writes
some info-message into this text file:

```
[OCR skipped on page 1][OCR skipped on page 2]
```

Docspell cannot reliably tell, wether this is extracted text or not.
It would be reqiured to load the pdf and check its contents. This is a
bit of bad luck, because everything would just work already. So it
requires a (small) change in the text-extraction step. By default,
text extraction happens on the source file. For PDFs, text extraction
should now be run on the converted file, to avoid running OCR twice.

The converted pdf file is either be a text-pdf in the first place,
where ocrmypdf would only convert it to a PDF/A file; or it may be a
converted file containing the OCR-ed text as a pdf layer. If ocrmypdf
is disabled, the converted file and the source file are the same for
PDFs.

# Decision Outcome

Add ocrmypdf as an optional conversion from PDF to PDF. Ocrmypdf is
distributed under the GPL-3 license.
