+++
title = "File Processing"
description = "How Docspell processes files."
weight = 20
insert_anchor_links = "right"
[extra]
mktoc = true
+++

When uploading a file, it is only saved to the database together with
the given meta information. The file is not visible in the ui yet.
Then joex takes the next such file (or files in case you uploaded
many) and starts processing it. When processing finished, it the item
and its files will show up in the ui.

If an error occurs during processing, the item will be created
anyways, so you can see it. Depending on the error, some information
may not be available.

Processing files may require some resources, like memory and cpu. Many
things can be configured in the config file to adapt it to the machine
it is running on.

Important is the setting `docspell.joex.scheduler.pool-size` which
defines how many tasks can run in parallel on the machine running
joex. For machines that are not very strong, choosing a `1` is
recommended.


# Stages

```
DuplicateCheck ->
Extract Archives ->
Conversion to PDF ->
Text Extraction ->
Generate Previews ->
Text Analysis
```

These steps are executed sequentially. There are many config options
available for each step.

## External Commands

External programs are all configured the same way. You can change the
command (add, remove options etc) in the config file. As an example,
here is the `wkhtmltopdf` command that is used to convert html files
to pdf:

``` conf
docspell.joex.convert {
  wkhtmlpdf {
    command = {
      program = "wkhtmltopdf"
      args = [
        "-s",
        "A4",
        "--encoding",
        "{{encoding}}",
        "--load-error-handling", "ignore",
        "--load-media-error-handling", "ignore",
        "-",
        "{{outfile}}"
      ]
      timeout = "2 minutes"
    }
    working-dir = ${java.io.tmpdir}"/docspell-convert"
  }
}
```

Strings in `{{…}}` are replaced by docspell with the appropriate
values at runtime. However, based on your use case you can just set
constant values or add other options. This might be necessary when
there are different version installed where changes in the command
line are required. As you see for `wkhtmltopdf` the page size is fixed
to DIN A4. Other commands are configured like this as well.

For the default values, please see the [configuration
page](@/docs/configure/_index.md#joex).

## Duplicate Check

If specified, the uploaded file is checked via a sha256 hash, if it
has been uploaded before. If so, it is removed from the set of
uploaded files. You can define this with the upload metadata.

If this results in an empty set, the processing ends.


## Extract Archives

If a file is a `zip` or `eml` (e-mail) file, it is extracted and its
entries are added to the file set. The original (archive) file is kept
in the database, but removed from further processing.


## Conversion to PDF

All files are converted to a PDF file. How this is done depends on the
file type. External programs are required, which must be installed on
the machine running joex. The config file allows to specify the exact
commands used.

See the section `docspell.joex.convert` in the config file.

The following config options apply to the conversion as a whole:

``` conf
docspell.joex.convert {
  converted-filename-part = "converted"
  max-image-size = ${docspell.joex.extraction.ocr.max-image-size}
}
```

The first setting defines a suffix that is appended to the original
file name to name the converted file. You can set an empty string to
keep the same filename as the original. The extension is always
changed to `.pdf`, of course.

The second option defines a limit for reading images. Some images may
be small as a file but uncompressed very large. To avoid allocating
too much memory, there is a limit. It defaults to 14mp.

### Html

Html files are converted with the external tool
[wkhtmltopdf](https://wkhtmltopdf.org/). It produces quite nice
results by using the webkit rendering engine. So the resulting PDF
looks just like in a browser.


### Images

Images are converted using
[tesseract](https://github.com/tesseract-ocr).

This might be interesting, if you want to try a different language
that is not available in docspell's settings yet. Tesseract also adds
the extracted text as a separate layer to the PDF.

For images, tesseract is configured to create a text and a pdf file.

### Text

Plaintext files are treated as markdown. You can modify the results by
providing some custom css.

The resulting HTML files are then converted to PDF via `wkhtmltopdf`
as described above.

### Office

To convert office files, [Libreoffice](https://www.libreoffice.org/)
is required and used via the command line tool
[unoconv](https://github.com/unoconv/unoconv).

To improve performance, it is recommended to start a libreoffice
listener by running `unoconv -l` in a separate process.


### PDF

PDFs can be converted into PDFs, which may sound silly at first. But
PDFs come in many different flavors and may not contain a separate
text layer, making it impossible to "copy & paste" text in them. So
you can optionally use the tool
[ocrmypdf](https://github.com/jbarlow83/OCRmyPDF) to create a PDF/A
type PDF file containing a text layer with the extracted text.

It is recommended to install ocrympdf, but it also is optional. If it
is enabled but fails, the error is not fatal and the processing will
continue using the original pdf for extracting text. You can also
disable it to remove the errors from the processing logs.

The `--skip-text` option is necessary to not fail on "text" pdfs
(where ocr is not necessary). In this case, the pdf will be converted
to PDF/A.


## Text Extraction

Text extraction also depends on the file type. Some tools from the
convert section are used here, too.

Text is tried to extract from the original file. If that can't be done
or results in an error, the converted file is tried next.

### Html

Html files are not used directly, but the converted PDF file is used
to extract the text. This makes sure that the text is extracted you
actually see. The conversion is done anyways and the resulting PDF
already has a text layer.

### Images

For images, [tesseract](https://github.com/tesseract-ocr) is used
again. In most cases this step is not executed, because the text has
already been extracted in the conversion step. But if the conversion
would have failed for some reason, tesseract is called here (with
different options).

### Text

This is obviously trivial :)

### Office

MS Office files are processed using a library without any external
tool. It uses [apache poi](https://poi.apache.org/) which is well
known for these tasks.

A rich text file (`.rtf`) is procssed by Java "natively" (using their
standard library).

OpenDocument files are proecessed using the ODS/ODT/ODF parser from
tika.

### PDF

PDF files are first checked for a text layer. If this returns some
text that is greater than the configured minimum length, it is used.
Otherwise, OCR is started for the whole pdf file page by page.


```conf
docspell.joex {
  extraction {
    pdf {
      min-text-len = 500
    }
  }
}
```

After OCR both texts are compared and the longer is used. Since PDFs
can contain text and images, it might be safer to always do OCR, but
this is something to choose by the user.

PDF ocr is comprised of multiple steps. At first only the first
`page-range` pages are extracted to avoid too long running tasks
(someone submit an ebook for example). But you can disable this limit
by setting a `-1`. After all, text that is not extracted, won't be
indexed either and is therefore not searchable. It depends on your
machine/setup.

Another limit is `max-image-size` which defines the size of an image
in pixel (`width * height`) where processing is skipped.

Then [ghostscript](http://pages.cs.wisc.edu/~ghost/) is used to
extract single pages into image files and
[unpaper](https://github.com/Flameeyes/unpaper) is used to optimize
the images for ocr. Unpaper is optional, if it is not found, it is
skipped, which may be a compromise on slow machines.

```conf
docspell.joex {
  extraction {
    ocr {
      max-image-size = 14000000
      page-range {
        begin = 10
      }
      ghostscript {
        command {
          program = "gs"
          args = [ "-dNOPAUSE"
                 , "-dBATCH"
                 , "-dSAFER"
                 , "-sDEVICE=tiffscaled8"
                 , "-sOutputFile={{outfile}}"
                 , "{{infile}}"
                 ]
          timeout = "5 minutes"
        }
        working-dir = ${java.io.tmpdir}"/docspell-extraction"
      }
      unpaper {
        command {
          program = "unpaper"
          args = [ "{{infile}}", "{{outfile}}" ]
          timeout = "5 minutes"
        }
      }
      tesseract {
        command {
          program = "tesseract"
          args = ["{{file}}"
                 , "stdout"
                 , "-l"
                 , "{{lang}}"
                 ]
          timeout = "5 minutes"
        }
      }
    }
  }
}
```

# Generating Previews

Previews are generated from the converted PDF of every file. The first
page of each file is converted into an image file. The config file
allows to specify a dpi which is used to render the pdf page. The
default is set to 32dpi, which results roughly in a 200x300px image.
For comparison, a standard A4 is usually rendered at 96dpi, which
results in a 790x1100px image.

```conf
docspell.joex {
  extraction {
    preview {
      dpi = 32
    }
  }
}
```

{% infobubble(mode="warning", title="Please note") %}

When this is changed, you must re-generate all preview images. Check
the api for this, there is an endpoint to regenerate all preview
images for a collective. There is also a bash script provided in the
`tools/` directory that can be used to call this endpoint.

{% end %}


# Text Analysis

This uses the extracted text to find what could be attached to the new
item. There are multiple things provided.

Docspell depends on the [Stanford NLP
Library](https://nlp.stanford.edu/software/) for its AI features.
Among other things they provide a classifier (used for guessing tags)
and NER annotators. The latter is also a classifier, that associates a
label to terms in a text. It finds out whether some term is probably
an organization, a person etc. This is then used to find matches in
your address book.

When docspell finds several possible candidates for a match, it will
show the first few to you. If then the first was not the correct one,
it can usually be fixed by a single click, because it is among the
suggestions.

## Classification

If you enabled classification in the config file, a model is trained
periodically from your files. This is used to guess a tag for the item
for new documents.

You can tell docspell how many documents it should use for training.
Sometimes (when moving?), documents may change and you only like to
base next guesses on the documents of last year only. This can be
found in the collective settings.

The admin can also limit the number of documents to train with,
because it affects memory usage.


## Natural Language Processing

NLP is used to find out which terms in a text may be a company or
person that is then used to find metadata in your address book. It can
also uses your complete address book to match terms in the text. So
there are two ways: using a statistical model, terms in a text are
identified as organization or person etc. This information is then
used to search your address book. Second, regexp rules are derived
from the address book and run against the text. By default, both are
applied, where the rules are run as the last step to identify missing
terms.

The statistical model approach is good, i.e. for large address books.
Normally, a document contains only very few organizations or person
names. So it is much more efficient to check these against your
address book (in contrast to the other way around). It can also find
things *not* in your address book. However, it might not detect all or
there are no statistical models for your language. Then the address
book is used to automatically create rules that are run against the
document.

These statistical models are provided by [Stanford
NLP](https://nlp.stanford.edu/software/) and are currently available
for German, English and French. All other languages can use the rule
approach. The statistcal models, however, require quite some memory –
depending on the size of the models which varies between languages.
English has a lower memory footprint than German, for example. If you
have a very large address book, the rule approach may also use a lot
memory.

In the config file, you can specify different modes of operation for
nlp processing as follows:

- mode `full`: creates the complete nlp pipeline, requiring the most
  amount of memory, providing the best results. I'd recommend to run
  joex with a heap size of a least 1.5G (for English only, it can be
  lower that that).
- mode `basic`: it only loads the NER tagger. This doesn't work as
  well as the complete pipeline, because some steps are simply
  skipped. But it gives quite good results and uses less memory. I'd
  recommend to run joex with at least 600m heap in this mode.
- mode `regexonly`: this doesn't load any statistical models and is
  therefore very memory efficient (depending on the address book size,
  of course). It will use the address book to create regex rules and
  match them against your document. It doesn't depend on a language,
  so this is available for all languages.
- mode = disabled: this disables nlp processing altogether

Note that mode `full` and `basic` is only relevant for the languages
where models are available. For all other languages, it is effectively
the same as `regexonly`.

The config file allows some settings. You can specify a limit for
texts. Large texts result in higher memory consumption. By default,
the first 10'000 characters are taken into account.

Then, for the `regexonly` mode, you can restrict the number of address
book entries that are used to create the rule set via
`regex-ner.max-entries`. This may be useful to reduce memory
footprint.

The setting `clear-stanford-nlp-interval` allows to define an idle
time after which the model files are cleared from memory. This allows
memory to be reclaimed by the OS. The timer starts after the last file
has been processed. If you can afford it, it is recommended to disable
it by setting it to `0`.
