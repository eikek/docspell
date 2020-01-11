---
layout: docs
position: 4
title: Documentation
---

# {{page.title}}

Docspell assists in organizing large amounts of PDF files that are
typically scanned paper documents. You can associate tags, set
correspondends, what a document is concerned with, a name, a date and
some more. If your documents are associated with this meta data, you
should be able to quickly find them later using the search
feature. But adding this manually to each document is a tedious
task. What if most of it could be attached automatically?

## How it works

Documents have two main properties: a correspondent (sender or
receiver that is not you) and something the document is about. Usually
it is about a person or some thing – maybe your car, or contracts
concerning some familiy member, etc.

1. You maintain a kind of address book. It should list all possible
   correspondents and the concerning people/things. This grows
   incrementally with each new unknown document.
2. When docspell analyzes a document, it tries to find matches within
   your address book. It can detect the correspondent and a concerning
   person or thing. It will then associate this data to your
   documents.
3. You can inspect what docspell has done and correct it. If docspell
   has found multiple suggestions, they will be shown for you to
   select one. If it is not correctly associated, very often the
   correct one is just one click away.

The set of meta data that docspell uses to draw suggestions from, must
be maintained manually. But usually, this data doesn't grow as fast as
the documents. After a while there is a quite complete address book
and only once in a while it has to be revisited.


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
- **tag**: an item can be tagged with custom tags. A tag can have a
  *category*. This is intended for grouping tags, for example a
  category `doctype` could be used to group tags like `bill`,
  `contract`, `receipt` etc. Usually an item is not tagged with more
  than one tag of a category.
- a **item date**: this is the date of the document – if this is not
  set, the created date of the item is used.
- a **due date**: an optional date indicating that something has to be
  done (e.g. paying a bill, submitting it) about this item until this
  date
- a **direction**: one of "incoming" or "outgoing"
- a **name**: some item name, defaults to the file name of the
  attachments
- some **notes**: arbitraty descriptive text. You can use markdown
  here, which is appropriately formatted in the web application.

### Collective

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
