+++
title = "Meta Data"
weight = 10
[extra]
mktoc = true
+++

# Metadata

Docspell processes each uploaded file. Processing involves extracting
archives, extracting text, anlyzing the extracted text and converting
the file into a pdf. Text is analyzed to find metadata that can be set
automatically. Docspell compares the extracted text against a set of
known meta data. The *Meta Data* page allows to manage this meta data:

- Tags
- Organizations
- Persons
- Equipments
- Folders
- Custom Fields

## Tags

Items can be tagged with multiple custom tags (aka labels). This
allows to describe many different workflows people may have with their
documents.

A tag can have a *category*. This is meant to group tags together. For
example, you may want to have a tag category *doctype* that is
comprised of tags like *bill*, *contract*, *receipt* and so on. Or for
workflows, a tag category *state* may exist that includes tags like
*Todo* or *Waiting*. Or you can tag items with user names to provide
"assignment" semantics. Docspell doesn't propose any workflow, but it
can help to implement some.

Docspell can try to predict a tag for new incoming documents
automatically based on your existing data. This requires to train an
algorithm. There are some caveats: the more data you have correctly
tagged, the better are the results. So it won't work well for maybe
the first 100 documents. Then the tags must somehow relate to a
pattern in the document text. Tags like *todo* or *waiting* probably
won't work, obviously. But the typical "document type" tag, like
*invoice* and *receipt* is a good fit! That is why you need to provide
a tag category so only sensible tags are being learned. The algorithm
goes through all your items and learns patterns in the text that
relate to the given tags. This training step can be run periodically,
as specified in your collective settings such that docspell keeps
learning from your already tagged data! More information about the
algorithm can be found in the config, where it is possible to
fine-tune this process.

Another way to have items tagged automatically is when an input PDF
file contains a list of keywords in its metadata section (this only
applies to PDF files). These keywords are then matched against the
tags in the database. If they match, the item is tagged with them.


## Organization and Person

The organization entity represents an non-personal (organization or
company) correspondent of an item. Docspell will choose one or more
organizations when processing documents and associate the "best" match
with your item.

The person entitiy can appear in two roles: It may be a correspondent
or the person an item is about. So a person is either a correspondent
or a concerning person. Docspell can not know which person is which,
therefore you need to tell this by checking the box "Use for
concerning person suggestion only". If this is checked, docspell will
use this person only to suggest a concerning person. Otherwise the
person is used only for correspondent suggestions.

Document processing uses the following properties:

- name
- websites
- e-mails

The website and e-mails can be added as contact information. If these
three are present, you should get good matches from docspell. All
other fields of an organization and person are not used during
document processing. They might be useful when using this as a real
address book.


## Equipment

The equipment entity is almost like a tag. In fact, it could be
replaced by a tag with a specific known category. The difference is
that docspell will try to find a match and associate it with your
item. The equipment represents non-personal things that an item is
about. Examples are: bills or insurances for *cars*, contracts for
*houses* or *flats*.

Equipments don't have contact information, so the only property that
is used to find matches during document processing is its name.


## Folders

Folders provide a way to divide all documents into disjoint subsets.
Unlike with tags, an item can have at most one folder or none. A
folder has an owner – the user who created the folder. Additionally,
it can have members: users of the collective that the owner can assign
to a folder.

When searching for items, the results are restricted to items that
have either no folder assigned or a folder where the current user is
owner or member. It can be used to control visibility when searching.
However: there are no hard access checks. For example, if the item id
is known, any user of the collective can see it and modify its meta
data.

One use case is, that you can hide items from other users, like bills
for birthday presents. In this case it is very unlikely that someone
can guess the item-id.

While folders are *not* taken into account when processing documents,
they can be specified with the upload request or a [source
url](@/docs/webapp/uploading.md#anonymous-upload) to have them
automatically set when files arrive.

## Custom Metadata

Docspell allows to create your own fields. Please see [this
page](@/docs/webapp/customfields.md) for more information.


# Document Language

An important setting is the language of your documents. This helps OCR
and text analysis. You can select between various languages. The
language can also specified with each [upload
request](@/docs/api/upload.md).

Go to the *Collective Settings* page and click *Document
Language*. This will set the lanugage for all your documents. It is
not (yet) possible to specify it when uploading.

The language has effects in several areas: text extraction, fulltext
search and text analysis. When extracting text from images, tesseract
(the external tool used for this) can yield better results if the
language is known. Also, solr (the fulltext search tool) can optimize
its index given the language, which results in better fulltext search
experience. The features of text analysis strongly depend on the
language. Docspell uses the [Stanford NLP
Library](https://nlp.stanford.edu/software/) for its great machine
learning algorithms. Some of them, like certain NLP features, are only
available for some languages – namely German, English, French and
Spanish. The reason is that the required statistical models are not
available for other languages. However, docspell can still run other
algorithms for the other languages, like classification and custom
rules based on the address book.

More information about file processing and text analysis can be found
[here](@/docs/joex/file-processing.md#text-analysis).
