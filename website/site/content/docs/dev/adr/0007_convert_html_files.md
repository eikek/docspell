+++
title = "Convert HTML Files"
weight = 80
+++

# Context and Problem Statement

How can HTML documents be converted into a PDF file that looks as much
as possible like the original?

It would be nice to have a java-only solution. But if an external tool
has a better outcome, then an external tool is fine, too.

Since Docspell is free software, the tools must also be free.


# Considered Options

* [pandoc](https://pandoc.org/) external command
* [wkhtmltopdf](https://wkhtmltopdf.org/) external command
* [Unoconv](https://github.com/unoconv/unoconv) external command

Native (firefox) view:

{{ figure(file="example-html-native.jpg") }}

I downloaded the HTML file to disk together with its resources (using
*Save as...* in the browser).


## Pandoc

{{ figure(file="example-html-pandoc-latex.jpg") }}

{{ figure(file="example-html-pandoc-html.jpg") }}

Not showing the version using `context` pdf-engine, since it looked
very similiar to the latex variant.


## wkhtmltopdf

{{ figure(file="example-html-wkhtmltopdf.jpg") }}


## Unoconv


{{ figure(file="example-html-unoconv.jpg") }}


# Decision Outcome

wkhtmltopdf.

It shows the best results.
