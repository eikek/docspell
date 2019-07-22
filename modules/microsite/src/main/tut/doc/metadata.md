---
layout: docs
title: Adding Meta Data
---

# {{ page.title }}

## Meta Data

The processing can be controlled implicitely by the provided meta
data. The *Meta Data* page allows to manage this meta data. You can
create the following:

- Tags
- Organizations
- Persons
- Equipments

### Tags

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

The tags are *not* taken into account when processing. Docspell will
not automatically associate tags to your items. The tags are only
meant to be used manually.


### Organization and Person

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

The website an e-mails can be added as contact information. If these
three are present, you should get good matches from docspell. All
other fields of an organization and person are not used during
document processing. They might be useful when using this as a real
address book.


### Equipment

The equipment entity is almost like a tag. In fact, it could be
replaced by a tag with a specific known category. The difference is
that docspell will try to find a match and associate it with your
item. The equipment represents non-personal things that an item is
about. Examples are: bills or insurances for *cars*, contracts for
*houses* or *flats*.

Equipments don't have contact information, so the only property that
is used to find matches during document processing is its name.


## Document Language

An important setting is the language of your documents. This helps OCR
and text analysis. You can select between English and German
currently.

Go to the *Collective Settings* page and click *Document
Language*. This will set the lanugage for all your documents. It is
not (yet) possible to specify it when uploading.
