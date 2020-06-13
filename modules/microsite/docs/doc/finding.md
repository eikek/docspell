---
layout: docs
title: Finding Items
permalink: doc/finding
---

# {{ page.title }}

Items can be searched by their annotated meta data. The landing page
shows a list of current items. Items are displayed sorted by their
date, newest first.

Docspell has two modes for searching: a simple search bar and a search
menu with many options. Both are active at the same time, but only one
is visible. You can switch between them without affecting the results.


## Search Bar

<img style="float:right;" src="../img/search-bar.png" height="50">

By default, the search bar is shown. It searches in the name
properties of the following meta data:

- the item name
- the notes
- correspondent organization and person
- concerning person and equipment

A wildcard `*` can be used at the start or end of a search term to do
a substring match. A `*` means "everything". So a term `*company`
matches all names ending in `company` and `*company*` matches all
names containing the word `company`. The matching is case insensitive.

Docspell adds a `*` to the front and end of a term automatically,
unless one of the following is true:

- The term already has a wildcard.
- The term is enclosed in quotes `"`.

You can go to the search menu by clicking the left icon in the search
bar.

If the search bar shows a little blue bubble, it means that there are
more search fields filled out in the search menu. In this case the
results are not only restricted by the search term given in the
search-bar, but also by what is specified in the search menu.


## Search Menu

<img style="float:right;" src="../img/search-menu.png" width="250">

The search menu can be opened by clicking the left icon in the top
bar. It shows some options to constrain the item list:

### Show new items

Clicking the checkbox "Only new" shows items that have not been
"Confirmed". All items that have been created by docspell and not
looked at are marked as "new" automatically.

### Names

Searches in names of certain properties. The `All Names` field is the
same as the search in the search bar (see above).

The `Name` field only searches in the name property of an item.

### Tags

Specify a list of tags that the items must have. When adding tags to
the "Include" list, an item must have all these tags in order to be
included in the results.

When adding tags to the "Exclude" list, then an item is removed from
the results if it has at least one of these tags.

### Correspondent

Pick a correspondent to show only these items.

### Concerned

Pick a concerned entity to show only these items.

### Date

Specify a date range to show only items whose date property is within
this range. If you want to see items of a specific day, choose the
same day for both fields.

For items that don't have an explicitly date property set, the created
date is used.

### Due Date

Specify a date range to show only items whose due date property is
within this range. Items without a due date are not shown.


### Direction

Specify whether to show only incoming, only outgoing or all items.


## Screencast

<video width="100%" controls>
  <source src="../static/docspell-search-2020-06-13.webm" type="video/webm">
  Your browser does not support the video tag.
</video>
