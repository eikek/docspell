+++
title = "Prerequisites"
weight = 10
+++

# Prerequisites

The two components have one prerequisite in common: they both require
Java to run. While this is the only requirement for the *REST server*,
the *Joex* components requires some more external programs.

The rest server and joex components are not required to "see" each
other, though it is recommended.

## Java

Very often, Java is already installed. You can check this by opening a
terminal and typing `java -version`. Otherwise install Java using your
package manager or see [this site](https://adoptopenjdk.net/) for
other options.

It is enough to install the JRE. The JDK is required, if you want to
build docspell from source. For newer versions, the JRE is not shipped
anymore, simply use JDK then.

Docspell has been tested with Java 17 (or sometimes referred to as JDK
17). The provided packages are build using JDK 17. However, it also
works on newer java versions. The provided docker images use JDK17.

The next tools are only required on machines running the *Joex*
component.

## External Programs for Joex

- [Ghostscript](https://www.ghostscript.com/) (the `gs` command) is
  used to extract/convert PDF files into images that are then fed to
  ocr. It is available on most GNU/Linux distributions.
- [Unpaper](https://github.com/Flameeyes/unpaper) is a program that
  pre-processes images to yield better results when doing ocr. If this
  is not installed, docspell tries without it. However, it is
  recommended to install, because it [improves text
  extraction](https://github.com/tesseract-ocr/tesseract/wiki/ImproveQuality)
  (at the expense of a longer runtime).
- [Tesseract](https://github.com/tesseract-ocr/tesseract) is the tool
  doing the OCR (converts images into text). It can also convert
  images into pdf files. It is a widely used open source OCR engine.
  Tesseract 3 and 4 should work with docspell; you can adopt the
  command line in the configuration file, if necessary.
- [Unoconv](https://github.com/unoconv/unoconv) is used to convert
  office documents into PDF files. It uses libreoffice/openoffice.
- [wkhtmltopdf](https://wkhtmltopdf.org/) is used to convert HTML into
  PDF files.
- [OCRmyPDF](https://github.com/jbarlow83/OCRmyPDF) can be optionally
  used to convert PDF to PDF files. It adds an OCR layer to scanned
  PDF files to make them searchable. It also creates PDF/A files from
  the input pdf.

The performance of `unoconv` can be improved by starting `unoconv -l`
in a separate process. This runs a libreoffice/openoffice listener and
therefore avoids starting one each time `unoconv` is called.

### Example Debian

On Debian this should install all joex requirements:

``` bash
sudo apt-get install ghostscript tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf
```

# Apache SOLR

SOLR is a very powerful fulltext search engine and can be used to
provide the fulltext search feature. This feature is disabled by
default, so installing SOLR is optional.

When installing manually (i.e. not via docker), just install solr and
create a core as described in the [solr
documentation](https://solr.apache.org/guide/8_4/installing-solr.html).
That will provide you with the connection url (the last part is the
core name).

Then start solr with `-Dsolr.modules=analysis-extras`
to enable some additional analyzer like `icu` for `Khmer` language etc
as described [here](https://solr.apache.org/guide/solr/latest/indexing-guide/language-analysis.html#hebrew-lao-myanmar-khmer),
which we used for tokenization and segmentation for `Khmer` language in docspell.

When using the provided `docker-compose.yml` setup, SOLR is already setup.

SOLR must be reachable from all joex and all rest server components.

{% infobubble(title="Multiple fulltext search backends") %}

Docspell can also use
[PostgreSQL](@/docs/configure/fulltext-search.md#postgresql) as its
fulltext search backend. This is not as powerful, but doesn't require
to install SOLR.

{% end %}


# Database

Both components must have access to a SQL database. The SQL database
contains all data (including binary files by default) and is the
central component of docspell. Docspell has support these databases:

- PostreSQL
- MariaDB (>= 10.6)
- H2

The H2 database is an interesting option for personal and mid-size
setups, as it requires no additional work. It is integrated into
docspell and works really well out of the box. It is also configured
as the default database.

When using H2, make sure that all components access the same database
– the jdbc url must point to the same file. Then, it is important to
add the options
`;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE` at the end
of the url. See the [config page](@/docs/configure/database.md) for
an example.

For larger installations, PostgreSQL is recommended. Create a database
and a user with enough privileges (read, write, create table) to that
database.
