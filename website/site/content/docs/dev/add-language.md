+++
title = "Adding new language"
weight = 30
+++

# Adding a new language for document processing

Then there are other commits and issues to look at:

- [Add Lithuanian](https://github.com/eikek/docspell/issues/1540) and [PR](https://github.com/eikek/docspell/pull/1559/commits/9d69401fea8ff07330c8a9116bd0d987827317c9)
- [Add Polish](https://github.com/eikek/docspell/issues/1345) and [PR](https://github.com/eikek/docspell/pull/1559/commits/5ec311c331f1f78cc483cce54d5ab0e08454fea8)
- [Add Spanish language](https://github.com/eikek/docspell/commit/26dff18ae0d32ce2b32b4d11ce381ada0e99314f)
- [Add Latvian language](https://github.com/eikek/docspell/issues/679) and [PR](https://github.com/eikek/docspell/pull/694/commits/9991ad5fcc43ccefe011a6cc4d01bdae4bcd4573)
- [Add Japanese language](https://github.com/eikek/docspell/issues/948) and [PR](https://github.com/eikek/docspell/pull/961/commits/f994d4b2488e64668ee064676f8c6469d9ccc1be), had some corrections: [1](https://github.com/eikek/docspell/commit/c59d4f8a6d021ec4b01a92320c211248503f16a5), [Issue](https://github.com/eikek/docspell/issues/973), [2](https://github.com/eikek/docspell/pull/2505), [Issue](https://github.com/eikek/docspell/issues/2445)
- [Add Hebrew language](https://github.com/eikek/docspell/pull/1027)

Some older commits may be a bit out of date, but still show the
relevant things to do. These are:

- add it to `Language.scala`, create a new `case object` and add it to
  the `all` list (then fix compile errors)
- define a list of month names to support date recognition and update
  `DateFind.scala` to recognize date patterns for that language. Add
  some tests to `DateFindTest`. While writing test-cases, you can check
  them via `sbt`'s command prompt as following:
    ```
    testOnly docspell.analysis.date.DateFindTest
    ```
- add it to joex' dockerfile to be available for tesseract
- update the solr migration/field definitions in `SolrSetup`. Create a
  new solr migration that adds the content field for the new
  language - it is a copy&paste from other similar changes.
- update `FtsRepository` for the PostgreSQL fulltext search variant:
  if not sure, use `simple` here
- update the elm file so it shows up on the client. Also requires to
  add translations in `Messages.Data.Language`

## Test

Check if everything is fine with `sbt Test/compile`. After the project
compiles without errors, run `sbt fix` to apply formatting fixes.

It would be good to startup docspell and check the new lanugage a bit,
including whether fulltext search is working.

Sometimes, SOLR doesn't support a language. In this case the migration
needs to first add the new *field type*. There are examples for
Lithuanian and Hebrew in the code.

For the docker image, you can run

```bash
PLATFORMS=linux/amd64 ./build.sh 0.36.0-SNAPSHOT
```

in `docker/dockerfile` directory to build the docker image (just
choose some version, it doesn't matter).

## Non-NLP only

Note that this is without support for NLP. Including support for NLP
means that the [stanford nlp](https://github.com/stanfordnlp/CoreNLP)
library needs to provide models for it and these must be included in
the build and tested a bit.

## Opening issues on Github

You can also open an issue on github requesting to support a language.
I kindly ask to include all necessary information, like in
[this](https://github.com/eikek/docspell/issues/1540) issue. I know
that I can dig it out from websites, but it would be nice to have
everything ready. Also it is better to know from a local person some
details, like which date patterns are more likely to appear than
others.
