+++
title = "Introduction"
weight = 0
description = "Gives a short introduction to the goals of docspell and an overview of the components involved when running docspell."
insert_anchor_links = "right"
[extra]
mktoc = true
+++

# Introduction

Docspell aims to be a simple yet effective document organizer that
makes stowing documents away very quick and finding them later
reliable (and also fast). It doesn't require technical background or
studying huge manuals in order to use it. With this in mind, it is
rather opinionated and more targeted for home use and small/medium
organizations.

Docspell analyzes the text of your files and tries to find metadata
that will be annotated automatically. This metadata is taken from an
address book that must be maintained manually. Docspell then looks for
candidates for:

- Correspondents
- Concerned person or things
- A date

It will propose a few candidates and sets the most likely one to your
item.

This might be wrong, so it is recommended to curate the results.
However, very often the correct one is either set or within the
proposals where you fix it by a single click.

Besides these properties, there are more metadata you can use to
organize your files, for example tags, folders and notes.

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

The *joex* is the component that does the “heavy work”, excuting
long-running tasks, like processing files or importing your mails
periodically. While the joex component also exposes a small REST api
for controlling it, the user interface is all inside the rest server
api.

The rest server and the job executor can be started multiple times in
order to scale out. It must be ensured, that all connect to the same
database.

The fulltext search index is another separate component, where
currently only SOLR is supported. SOLR also supports running in a
distributed way. Fulltext search is optional, so the SOLR component is
not required if docspell is run without fulltext search support.


# Terms

In order to better understand the following pages, some terms are
explained.

## Item

An *Item* is roughly your document, only that an item may span
multiple files, which are called **attachments**. An item has **meta
data** associated:

- a **correspondent**: the other side of the communication. It can be
  an organization or a person.
- a **concerning person** or **equipment**: a person or thing that
  this item is about. Maybe it is an insurance contract about your
  car.
- **tag**: an item can be tagged with one or more tags (or labels). A
  tag can have a *category*. This is intended for grouping tags, for
  example a category `doctype` could be used to group tags like
  `bill`, `contract`, `receipt` etc. Usually an item is not tagged
  with more than one tag of a category.
- a **folder**: a folder is similiar to a tag, but an item can only be
  in exactly one folder (or none). Furhtermore folders allow to
  associate users, so that items are only visible to the users who are
  members of a folder.
- an **item date**: this is the date of the document – if this is not
  set, the created date of the item is used.
- a **due date**: an optional date indicating that something has to be
  done (e.g. paying a bill, submitting it) about this item until this
  date
- a **direction**: one of "incoming" or "outgoing"
- a **name**: some item name, defaults to the file name of the
  attachments
- some **notes**: arbitrary descriptive text. You can use markdown
  here, which is properly formatted in the web application.

## Collective

The users of the application are part of a **collective**. A
**collective** is a group of users that share access to the same
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
