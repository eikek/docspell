+++
title = "Finding Items"
weight = 30
[extra]
mktoc = true
+++

Items can be searched by their annotated meta data and their contents
using full text search. The landing page shows a list of current
items. Items are displayed sorted by their date, newest first.

Docspell has two modes for searching: a simple search bar and a search
menu with many options. Both are active at the same time, but only one
is visible. You can switch between them without affecting the results.


# Search Bar

{{ imgright(file="search-bar.png") }}

By default, the search bar is shown. It provides a shortcut to search
for names and a mode for fulltext-only search. The dropdown contains
the different options.

## The *Names* option {#names}

This option corresponds to the same named field in the search menu. If
you switch between search menu and search bar (by clicking the icon on
the left), you'll see that they are the same fields. Typing in the
search bar also fills the corresponding field in the search menu (and
vice versa).

The *Names* searches in the item name, names of correspondent
organization and person, and names of concering person and equipment.
It uses a simple substring search. When searching with this option
active, it simply submits the (hidden) search menu. So if the menu has
other fields filled out, they will affect the result, too.

If the left button in the search bar shows a little blue bubble, it
means that there are more search fields filled out in the search menu
that you currently can't see. In this case the results are not only
restricted by the search term given in the search-bar, but also by
what is specified in the search menu.


## The *Contents Only* option {#contents-only}

This option has no corresponding part in the search menu. Searching
with this option active, there is a full text search done in:
attachments contents, attachment names, item name and item notes.

The results are not ordered by item date, but by relevance with
respect to the search term. This ordering is returned from the full
text search engine and is simply transfered unmodified.


# Search Menu

{{ imgright(file="search-menu.png") }}

The search menu can be opened by clicking the left icon in the top
bar. It shows some options to constrain the item list:

## Show new items

Clicking the checkbox "Only new" shows items that have not been
"Confirmed". All items that have been created by docspell and not
looked at are marked as "new" automatically.

## Fulltext and Name Search

You can choose tags or correspondents in the search menu and further
restrict the results using full text search with the *content* field.

If this is the only filled field, then a normal fulltext search is
done. It is exactly the same as filling out the *Contents Only* search
bar. However, if some other fields are also set, then first a search
using all other fields is done and these results are then further
constraint by a fulltext search.

You can switch to "Name Search" using the little icon on the right.
This will then only search in item names and notes.

## Tags & Tag Categories

Click on a tag to show only items with this tag, the tag is marked
with a check (✔) icon. Click again, to show only items that are not
tagged with the tag. Then the tag is marked with a minus (–) icon.
Clicking a third time deselects the tag and the icon goes back to a
"tag" icon.

By default, the most used tags are shown and you can click on *Show
more…* to list all. How many tags are displayed can be changed in the
ui settings (go to *User Settings* ‣ *Ui Settings*).

When multiple tags are checked (✔), only items are shown that have all
these tags. When multiple tags are excluded (–), then only items are
shown that don't have these tags.

The same applies to tag categories. You can show all items that have
at least on tag of a checked (✔) category. Or you can list all items
that have no tag of a category (–).

You can also use drag&drop to tag items in this view. Simply drag an
item card and drop it on a tag, this will toggle the tag on the item.
If the item was tagged already, the tag is removed, otherwise added.

<div class="columns is-centered">
  <div class="column">
  {{ imgnormal(file="drop-tag.png", width="400px") }}
  </div>
</div>

## Folder

Select a folder to only show items in that folder. Only folders where
the current user has access are displayed. As with tags, there are
only a few folders shown and you can expand all with a *Show more*
link. How many folders are displayed without this link can be
configured in the ui settings.

If no folder is set, all accessible items are shown. These are all
items that either have no folder set, or a folder where the current
user is member.

It is possible to put items into a folder in this view via drag&drop.
Simply drag an item card and drop it on a folder. If dropped on the
*Folders* header, the item is moved outside the folder.

## Correspondent

Pick a correspondent to show only these items.

## Concerned

Pick a concerned entity to show only these items.

## Custom Fields

You can choose one or more custom field to search for. You can use
wildcards (`*`) at the beginning and/or end of a search term, too. To
find items that have any value, use a single `*`.


## Date

Specify a date range to show only items whose date property is within
this range. If you want to see items of a specific day, choose the
same day for both fields.

For items that don't have an explicitly date property set, the created
date is used.

## Due Date

Specify a date range to show only items whose due date property is
within this range. Items without a due date are not shown.


## Direction

Specify whether to show only incoming, only outgoing or all items.


# Customize Substring Search

The substring search of the *All Names* and *Name* field can be
customized in the following way: A wildcard `*` can be used at the
start or end of a search term to do a substring match. A `*` means
"everything". So a term `*company` matches all names ending in
`company` and `*company*` matches all names containing the word
`company`. The matching is case insensitive.

Docspell adds a `*` to the front and end of a term automatically,
unless one of the following is true:

- The term already has a wildcard.
- The term is enclosed in quotes `"`.


# Full Text Search


## The Query

The query string for full text search is very powerful. Docspell
currently supports [Apache SOLR](https://lucene.apache.org/solr/) as
full text search backend, so you may want to have a look at their
[documentation on query
syntax](https://lucene.apache.org/solr/guide/8_4/query-syntax-and-parsing.html#query-syntax-and-parsing)
for a in depth guide.

- Wildcards: `?` matches any single character, `*` matches zero or
  more characters
- Fuzzy search: Appending a `~` to a term, results in a fuzzy search
  (search this term and similiar spelled ones)
- Proximity Search: Search for terms that "near" each other, again
  using `~` appended to a search phrase. Example: `"cheese cake"~5`.
- Boosting: apply more weight to a term with `^`. Example: `cheese^4
  cake` – cheese is 4x more important.

Docspell will preprocess the search query to prepare a query for SOLR.
It will by default search all indexed fields, which are: attachment
contents, attachment names, item name and item notes.


## The Results

When using full text search, each item in the result list is annotated
with the highlighted occurrence of the match.

<figure class="image">
  <img src="/img/fts-feature.png">
</figure>
