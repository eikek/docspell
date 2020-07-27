+++
title = "Extract Text from Files"
weight = 120
+++


# Context and Problem Statement

With support for more file types there must be a way to extract text
from all of them. It is better to extract text from the source files,
in contrast to extracting the text from the converted pdf file.

There are multiple options and multiple file types. Again, most
priority is to use a java/scala library to reduce external
dependencies.

# Considered Options

## MS Office Documents

There is only one library I know: [Apache
POI](https://poi.apache.org/). It supports `doc(x)` and `xls(x)`.
However, it doesn't support open-document format (odt and ods).

## OpenDocument Format

There are two libraries:

- [Apache Tika Parser](https://tika.apache.org/)
- [ODFToolkit](https://github.com/tdf/odftoolkit)

*Tika:* The tika-parsers package contains an opendocument parser for
extracting text. But it has a huge dependency tree, since it is a
super-package containing a parser for almost every common file type.

*ODF Toolkit:* This depends on [Apache Jena](https://jena.apache.org)
and also pulls in quite some dependencies (while not as much as
tika-parser). It is not too bad, since it is a library for
manipulating opendocument files. But all I need is to only extract
text. I created tests that extracted text from my odt/ods files. It
worked at first sight, but running the tests in a loop resulted in
strange nullpointer exceptions (it only worked the first run).

## Richtext

Richtext is supported by the jdk (using `RichtextEditorKit` from
swing).

## PDF

For "image" pdf files, tesseract is used. For "text" PDF files, the
library [Apache PDFBox](https://pdfbox.apache.org) can be used.

There also is [iText](https://github.com/itext/itext7) with a AGPL
license.

## Images

For images and "image" PDF files, there is already tesseract in place.

## HTML

HTML must be converted into a PDF file before text can be extracted.

## Text/Markdown

These files can be used as-is, obviously.


# Decision Outcome

- MS Office files: POI library
- Open Document files: Tika, but integrating the few source files that
  make up the open document parser. Due to its huge dependency tree,
  the library is not added.
- PDF: Apache PDFBox. I know this library better than itext.
