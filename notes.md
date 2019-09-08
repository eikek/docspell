# Prereq

## Rest Server and Joex

### Java

Docspell (restserver and joex) requires a Java Virtual Machine to
run. On many systems this is already installed. If not, install it
usin your package manager, or look at [this
site](https://adoptopenjdk.net/) to find something to install.

That's everything required for the rest server. The joex component
needs more external programs for processing files.

## Joex

The Job Executor reads your documents, extracts and analyzes the text
and then tries to find matches from your meta data. This relies on
external tools that you have to install using your package manager.

This process needs lots of CPU power and also some RAM (up to
1G). While it can run on less powerful machines, processing times can
get quite long.

### ghostscript

The [ghostscript](http://pages.cs.wisc.edu/~ghost/) command (`gs`) is
used to create images from pdf files.


### unpaper

The [unpaper](https://github.com/Flameeyes/unpaper) tool is not really
required, but it usually improves OCR results a lot.


### tesseract

[Tesseract](https://github.com/tesseract-ocr/tesseract) is a open
source OCR engine that is used to extract text from (scanned) images.


## Database

Docspell requires a SQL database. All components must be configured to
point to the same database.

It can work with PostgreSQL, MariaDB and H2.

While PostgreSQL and MariaDB are full-featured database servers, the
H2 database is very nice for personal setups as it doesn't require any
setup. The default database is H2.

When using MariaDB or PostgreSQL, the database must be created
first. The schema is then created by the application on startup. For
the very first start, components should not be started at the same
time. Otherwise schema migration may get confused.


# Signup

## Creating a new account

Go to the register page:
<http://localhost:7880/app/index.html#/register>

This page is also linked from the login page, which shows up on first
access.

Your login name consists of a collective- and a user name (see [the
explanation about collecitve](../doc.html#collective)). So you need to
give a name for both. They can be the same. Then you need to provide a
password and that's it.


## Logging in

Once registered, you can login with your login name and password. The
login name has this format:

```
collective-name/user-name
```

The collective name comes first, then a separator (a slash) and then
the user name.

If both, collective- and user name, are equal, it is enough to just
give one. So the long login name `eike/eike` becomes just `eike`.


# Manage Data

Docspell needs some pool of metadata that can be used to draw
suggestions from. This meta data has to be provided by you.

Clicking on menu icon in the top right corner, opens the menu. Click
"Manage Data" and you'll get to a page where you can edit the
metadata.

Meta data about items is roughly grouped into two parts:

1. The correspondent
2. The thing or person the item is about

What this exactly is, is up to you. A bill may be "concerning" the
thing you bought. But it may also be "concerning" your child, because
it was a gift.

The correspondent is divided into organizations and persons.



TODO: what data is used for making suggestions? only name? phone number?


## Tag

Tags are a very generic way to attach labels to items. Tags are not
suggested by docspell, but are meant to be used manually. They can be
used to implement some workflows.

For example, you might have tags "todo", "waiting" etc. When going
through new documents you could add a 'todo' tag and once you get
around doing the task, you can remove it.

A tag has another property called "category" for organizing tags into
groups. The idea is to use it for a set of tags, where normally just
one can apply to an item. For example, category 'doctype' may consist
of "bill", "contract" or "receipt". This would name the document type,
and normally an item cannot be more than one. I'll say normally,
because it depends on your data and mindset around it, there is no
fixed clear definition.


## Equipment


The "equipment" is used for the "concerning thing" – something the
item is about. This could be used for things that are around some
time, like a car, or maybe a flat or house you let.


## Person

A person is used for the "concerning" part and for the "correspondent"
part of an item.

When adding a person you can check whether docspell should use it to
suggest the concerning part or the correspondent part.


## Organization

The organization is used for the correspondent part. It includes
companies and other non-personal entities that are correspondents.

# Install

Docspell consists of two components:

- rest server: the rest server also provides the web application and
  can be used to manage items and upload files
- joex (job executor): this component takes new files from the
  database and processes them. It requires much more power than the
  rest server.

There are [packages](https://github.com/eikek/docspell/releases) for
some linux distributions, OSX and the generic ZIP files to download.

The default configuration uses a simple file-base database that is
assumed in the current working directory and created if not
existing. Thus it is required to start joex and restserver from within
the same working directory when using the default configuration. It is
recommended to provide a custom configuration file. It can be given as
an argument to the executable.

H2 works really well and you can just use it for a personal setup. For
more users, a database like PostgreSQL is recommended.

## Multiple Instances

Both components can be startet multiple times. The rest-server can run
multiple instances behind a load balancer. Multiple joex instances can
also be deployed, which would all compete on processing files.

For this to work, there are some things to take care of:

- you need to specify unique `app-id`s in the configuration files of
  each instance
- when running multiple rest servers, all must share the same
  `server-secret`


## Database

Docspell requires a SQL database to work. But it also works with the
[H2](https://h2database.com) database, which is a no-setup database
using regular files.

Joex and rest-server must point to the same database. This even works
with H2, but you must set the `AUTO_START=TRUE` parameter at the
connection url.

Other database systems that should work:

- PostgreSQL
- MariaDB

## Raspberry Pi

It is possible to run Docspell completely on a Raspberry Pi (or
similiar) device. The rest server works quite well. But the joex
component uses many resources and on such a device the running times
for processing files are quite long. However, you can always fire up
another joex instance on a different machine, if you need it quicker.


# Documentation

Docspell can help organize your (digitalized) paper documents. You
need a scanner that scans your paper documents to PDF files. These
files can be organized with docspell. Search for "document scanner",
these are quite convenient. They usually have a network interface and
can place the files directly on your NAS, for example.

Docspell supports these two use cases:

### 1. Stow away paper documents quickly

Since most of the time, we receive (or create) documents, there should
be a *quick* way of stowing them away. Docspell can find and associate
metadata automatically. Even if you don't curate the results, there is
a good chance you'll find a document. So "stowing away" in this case
means just uploading the files to docspell. You do have to maintain a
list of possible correspondents, though.

It is recommended to inspect the resutls and correct them. If there
are multiple suggestions, you can select from the top 5 of them. Very
often, it includes the correct one. Docspell tries to make curating
not a tedious engagement.

### 2. Find a document

Usually most of the paper documents is not of interest after just a
few days. But if you need a document, it is usually important to find
it.

Docspell helps here by providing means to search for documents based
on the associated meta data.


## Data Model / Naming

In order to better understand the following pages, here are some words
explained.

### Item

In docspell an *item* is the center of the data model. An item
represents one or more documents (files) that form a unit. Most of the
time it is probably one file. But an item can span multiple documents,
too. For example, some contracts come with appendixes that are
distributed as a separate document. It makes sense to put them both
togther into one "item".


### Collective

Docspell is like any other multi user application: users can manage
their own set of items.

But it also possible that multiple users share a set of items. For
example, for a familiy household it makes sense to have all members
access the data.

So in docspell there is a *collective* that represents a set of users
that share items. Each user within a collective has the same
permissions to access documents. The items don't belong to users, but
to their collective. For example, for a family household, it is
convenient to use the surname as collective id and a firstname or some
other nickname as user login.

That means, to uniquely identify yourself when signing in, you have to
give the collective name and your user login. By default it is
separated by a slash `/`, for example `smith/john`. If your user login
is the same as the collective id, you can omit one; so `eike/eike` can
be abbreviated to `eike`.
