+++
title = "File Processing"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 40
template = "docs.html"
+++

## File Processing

Files are being processed by the joex component. So all the respective
configuration is in this config only.

File processing involves several stages, detailed information can be
found [here](@/docs/joex/file-processing.md#text-analysis) and in the
corresponding sections in [joex default
config](@/docs/configure/main.md#joex).

Configuration allows to define the external tools and set some
limitations to control memory usage. The sections are:

- `docspell.joex.extraction`
- `docspell.joex.text-analysis`
- `docspell.joex.convert`

Options to external commands can use variables that are replaced by
values at runtime. Variables are enclosed in double braces `{{…}}`.
Please see the default configuration for what variables exist per
command.

### Classification

In `text-analysis.classification` you can define how many documents at
most should be used for learning. The default settings should work
well for most cases. However, it always depends on the amount of data
and the machine that runs joex. For example, by default the documents
to learn from are limited to 600 (`classification.item-count`) and
every text is cut after 5000 characters (`text-analysis.max-length`).
This is fine if *most* of your documents are small and only a few are
near 5000 characters). But if *all* your documents are very large, you
probably need to either assign more heap memory or go down with the
limits.

Classification can be disabled, too, for when it's not needed.

### NLP

This setting defines which NLP mode to use. It defaults to `full`,
which requires more memory for certain languages (with the advantage
of better results). Other values are `basic`, `regexonly` and
`disabled`. The modes `full` and `basic` use pre-defined lanugage
models for procesing documents of languaes German, English, French and
Spanish. These require some amount of memory (see below).

The mode `basic` is like the "light" variant to `full`. It doesn't use
all NLP features, which makes memory consumption much lower, but comes
with the compromise of less accurate results.

The mode `regexonly` doesn't use pre-defined lanuage models, even if
available. It checks your address book against a document to find
metadata. That means, it is language independent. Also, when using
`full` or `basic` with lanugages where no pre-defined models exist, it
will degrade to `regexonly` for these.

The mode `disabled` skips NLP processing completely. This has least
impact in memory consumption, obviously, but then only the classifier
is used to find metadata (unless it is disabled, too).

You might want to try different modes and see what combination suits
best your usage pattern and machine running joex. If a powerful
machine is used, simply leave the defaults. When running on an
raspberry pi, for example, you might need to adjust things.

### Memory Usage

The memory requirements for the joex component depends on the document
language and the enabled features for text-analysis. The `nlp.mode`
setting has significant impact, especially when your documents are in
German. Here are some rough numbers on jvm heap usage (the same file
was used for all tries):

<table class="striped-basic">
<thead>
  <tr>
     <th>nlp.mode</th>
     <th>English</th>
     <th>German</th>
     <th>French</th>
 </tr>
</thead>
<tfoot>
</tfoot>
<tbody>
  <tr><td>full</td><td>420M</td><td>950M</td><td>490M</td></tr>
  <tr><td>basic</td><td>170M</td><td>380M</td><td>390M</td></tr>
</tbody>
</table>

Note that these are only rough numbers and they show the maximum used
heap memory while processing a file.

When using `mode=full`, a heap setting of at least `-Xmx1400M` is
recommended. For `mode=basic` a heap setting of at least `-Xmx500M` is
recommended.

Other languages can't use these two modes, and so don't require this
amount of memory (but don't have as good results). Then you can go
with less heap. For these languages, the nlp mode is the same as
`regexonly`.

Training the classifier is also memory intensive, which solely depends
on the size and number of documents that are being trained. However,
training the classifier is done periodically and can happen maybe
every two weeks. When classifying new documents, memory requirements
are lower, since the model already exists.

More details about these modes can be found
[here](@/docs/joex/file-processing.md#text-analysis).


The restserver component is very lightweight, here you can use
defaults.
