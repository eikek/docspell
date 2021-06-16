+++
title = "Introduction"
weight = 0
description = "Gives a short introduction to the goals of docspell and an overview of the components involved."
insert_anchor_links = "right"
[extra]
mktoc = true
+++

# Introduction

Docspell aims to be a simple yet effective document organizer that
makes stowing documents away very quick and finding them later
reliable (and also fast). It is a bit opinionated and more targeted
for home use and small/medium organizations.

In contrast to many DMS, the main focus is not so much to provide all
kinds of features to manually create organizational structures, like
folder hierarchies, where you place the documents yourself. The
approach is to leave it as a big pile of documents, but extract and
attach metadata from each document. These are mainly properties that
emerge from the document itself. The reason is that this is possible
to automate. This makes it very simple to *add* documents, because
there is no time spent to think about where to put it. And it is
possible to apply different structures on top later, like show first
all documents of a specific correspondent, then all with tag
'invoice', etc. If these properties are attached to all documents, it
is really easy to find a document. It even can be combined with
fulltext search for the, hopefully rare, desperate cases.

Of course, it is also possible to add custom properties and arbitrary
tags.

Docspell analyzes the text to find metadata automatically. It can
learn from existing data and can apply
[NLP](https://en.wikipedia.org/wiki/Natural_language_processing)
techniques to support this. This metadata must be maintained manually
in the application. Docspell looks for candidates for:

- Correspondents
- Concerned person or things
- A date and due date
- Tags

For tags, it sets all that it thinks do apply. For the others, it will
propose a few candidates and sets the most likely one to your item.

This might be wrong, so it is recommended to curate the results.
However, very often the correct one is either set or within the
proposals where you fix it by a single click.

Besides these properties, there are more metadata you can use to
organize your files, for example custom fields, folders and notes.

Docspell is also for programmers. Everything is available via a REST
or HTTP api and can be easily used within your own scripts and tools,
for example using `curl`. There are also features for "advanced use"
and many configuration options.


# Components

Docspell consists of multiple components that run in separate
processes:

- REST server
- JOEX, short for *job executor*
- Fulltext Search Index (optional, currently Apache SOLR)

The REST server provides the Api and the web application. The web
application is a
[SPA](https://en.wikipedia.org/wiki/Single-page_application) written
in [Elm](https://elm-lang.org) and is a client to the REST api. All
features are available via a http/rest api.

The *joex* is the component that does the “heavy work”, executing
long-running tasks, like processing files or importing your mails
periodically. While the joex component also exposes a small REST api
for controlling it, the main user interface is all inside the rest
server api.

The rest server and the job executor can be started multiple times in
order to scale out. It must be ensured, that all connect to the same
database. And it is also recommended (though not strictly required),
that all components can reach each other.

The fulltext search index is another separate component, where
currently only [SOLR](https://solr.apache.org) is supported.
Fulltext search is optional, so the SOLR component is not required if
docspell is run without fulltext search support.


# Terms

In order to better understand the following pages, some terms are
explained.

## Item

An *item* is roughly your document, only that an item may span
multiple files, which are called *attachments*. An item has *meta
data* associated:

- a *correspondent*: the other side of the communication. It can be
  an organization or a person.
- a *concerning person* or *equipment*: a person or thing that
  this item is about. Maybe it is an insurance contract about your
  car.
- *tag*: an item can be tagged with one or more tags (or labels). A
  tag can have a *category*. This is intended for grouping tags, for
  example a category `doctype` could be used to group tags like
  `bill`, `contract`, `receipt` etc. Usually an item is not tagged
  with more than one tag of a category.
- a *folder*: a folder is similiar to a tag, but an item can only be
  in exactly one folder (or none). Furthermore folders allow to
  associate users, so that items are only visible to the users who are
  members of a folder.
- an *item date*: this is the date of the document – if this is not
  set, the created date of the item is used.
- a *due date*: an optional date indicating that something has to be
  done (e.g. paying a bill, submitting it) about this item until this
  date
- a *direction*: one of "incoming" or "outgoing"
- a *name*: some item name, defaults to the file name of the
  attachments
- some *notes*: arbitrary descriptive text. You can use markdown
  here, which is properly formatted in the web application.

## Collective

The users of the application are part of a *collective*. A
*collective* is a group of users that share access to the same
items. The account name is therefore comprised of a *collective name*
and a *user name*.

All users of a collective are equal; they have same permissions to
access all items. The items don't belong to a user, but to the
collective.

That means, to identify yourself when signing in, you have to give the
collective name and your user name. By default it is separated by a
slash `/`, for example `smith/john`. If your user name is the same as
the collective name, you can omit one; so `smith/smith` can be
abbreviated to just `smith`.

By default, all users can see all items of their collective. A
*folder* can be used to implement other visibilities: Every user can
create a folder and associate members. It is possible to put items in
these folders and docspell shows only items that are either in no
specific folder or in a folder where the current user is owner or
member.
