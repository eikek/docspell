+++
title = "Convert Text Files"
weight = 90
+++

# Context and Problem Statement

How can plain text and markdown documents be converted into a PDF
files?

Rendering images is not important here, since the files must be self
contained when uploaded to Docspell.

The test file is the current documentation page of Docspell, found in
`microsite/docs/doc.md`.

```
---
layout: docs
position: 4
title: Documentation
---

# {page .title}


Docspell assists in organizing large amounts of PDF files that are
...

## How it works

Documents have two ...

1. You maintain a kind of address book. It should list all possible
   correspondents and the concerning people/things. This grows
   incrementally with each new unknown document.
2. When docspell analyzes a document, it tries to find matches within
   your address ...
3. You can inspect ...

The set of meta data that docspell uses to draw suggestions from, must
be maintained ...


## Terms

In order to better understand these pages, some terms should be
explained first.

### Item

An **Item** is roughly your (pdf) document, only that an item may span
multiple files, which are called **attachments**. And an item has
**meta data** associated:

- a **correspondent**: the other side of the communication. It can be
  an organization or a person.
- a **concerning person** or **equipment**: a person or thing that
  this item is about. Maybe it is an insurance contract about your
  car.
- ...

### Collective

The users of the application are part of a **collective**. A
**collective** is a group of users that share access to the same
items. The account name is therefore comprised of a *collective name*
and a *user name*.

All users of a collective are equal; they have same permissions to
access all...
```

Then a plain text file is tried, too (without any markup).

```
Maecenas mauris lectus, lobortis et purus mattis

Duis vehicula mi vel mi pretium

In non mauris justo. Duis vehicula mi vel mi pretium, a viverra erat efficitur. Cras aliquam est ac eros varius, id iaculis dui auctor. Duis pretium neque ligula, et pulvinar mi placerat et. Nulla nec nunc sit amet nunc posuere vestibulum. Ut id neque eget tortor mattis tristique. Donec ante est, blandit sit amet tristique vel, lacinia pulvinar arcu.

Pellentesque scelerisque fermentum erat, id posuere justo pulvinar ut.
Cras id eros sed enim aliquam lobortis. Sed lobortis nisl ut eros
efficitur tincidunt. Cras justo mi, porttitor quis mattis vel,
ultricies ut purus. Ut facilisis et lacus eu cursus.

In eleifend velit vitae libero sollicitudin euismod:

- Fusce vitae vestibulum velit,
- Pellentesque vulputate lectus quis pellentesque commodo

the end.
```


# Considered Options

* [flexmark](https://github.com/vsch/flexmark-java) for markdown to
  HTML, then use existing machinery described in [adr
  7](@/docs/dev/adr/0007_convert_html_files.md)
* [pandoc](https://pandoc.org/) external command


## flexmark markdown library for java

Process files with [flexmark](https://github.com/vsch/flexmark-java)
and then create a PDF from the resulting html.

Using the following snippet:

``` scala
def renderMarkdown(): ExitCode = {
    val opts = new MutableDataSet()
    opts.set(Parser.EXTENSIONS.asInstanceOf[DataKey[util.Collection[_]]],
      util.Arrays.asList(TablesExtension.create(),
      StrikethroughExtension.create()));

    val parser = Parser.builder(opts).build()
    val renderer = HtmlRenderer.builder(opts).build()
    val reader = Files.newBufferedReader(Paths.get("in.txt|md"))
    val doc = parser.parseReader(reader)
    val html = renderer.render(doc)
    val body = "<html><head></head><body style=\"padding: 0 5em;\">" + html + "</body></html>"
    Files.write(
      Paths.get("test.html"),
      body.getBytes(StandardCharsets.UTF_8))

    ExitCode.Success
  }
```

Then run the result through `wkhtmltopdf`.

Markdown file:
{{ figure(file="example-md-java.jpg") }}

TXT file:
{{ figure(file="example-txt-java.jpg") }}


## pandoc

Command:

```
pandoc -f markdown -t html -o test.pdf microsite/docs/doc.md
```

Markdown/Latex:
{{ figure(file="example-md-pandoc-latex.jpg") }}

Markdown/Html:
{{ figure(file="example-md-pandoc-html.jpg") }}

Text/Latex:
{{ figure(file="example-txt-pandoc-latex.jpg") }}

Text/Html:
{{ figure(file="example-txt-pandoc-html.jpg") }}


# Decision Outcome

Java library "flexmark".

I think all results are great. It depends on the type of document and
what one expects to see. I guess that most people expect something
like pandoc-html produces for the kind of files docspell is for (it is
not for newspaper articles, where pandoc-latex would be best fit).

But choosing pandoc means yet another external command to depend on.
And the results from flexmark are really good, too. One can fiddle
with options and css to make it look better.

To not introduce another external command, decision is to use flexmark
and then the already existing html->pdf conversion.
