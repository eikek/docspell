+++
title = "Query Language"
weight = 55
description = "The query language is a powerful way to search for documents."
insert_anchor_links = "right"
[extra]
mktoc = true
+++


Docspell uses a query language to provide a powerful way to search for
your documents. It is targeted at "power users" and it needs to be
enabled explicitely in your user settings.

<div class="colums">
{{ figure(file="enable-powersearch.png") }}
</div>

This changes the search bar on the items list page to expect a query
as described below.

The search menu works as before, the query coming from the search menu
is combined with a query from the search bar.

For taking a quick look, head over to the [examples](#examples).

# Structure

The overall query is an expression that evaluates to `true` or `false`
when applied to an item and so selects whether to include it in the
results or not. It consists of smaller expressions that can be
combined via the common ways: `and`, `or` and `not`.

Simple expressions check some property of an item. The form is:

```
<field><operator><value>
```

For example: `tag=invoice` – where `tag` is the field, `=` the
operator and `invoice` the value. It would evaluate to `true` if the
item has a tag with name `invoice` and to `false` if the item doesn't
have a tag with name `invoice`.

Multiple expressions are separated by whitespace and are combined via
`AND` by default. To explicitely combine them, wrap a list of
expressions into one of these:

- `(& … )` to combine them via `AND`
- `(| … )` to combine them via `OR`

It is also possible to negate an expression, by prefixing it with a
`!`; for example `!tag=invoice`.

# The Parts

## Operators

There are 7 operators:

- `=` for equals
- `>` for greater-than
- `>=` for greater-equals
- `~=` for "in" (a shorter way to say "a or b or c or d")
- `:` for "like", this is used in a context-sensitive way
- `<` for lower than
- `<=` for lower-equal
- `!=` for not-equals

Not all operators work with every field.

## Fields

Fields are used to identify a property of an item. They also define
what operators are allowed. There are fields where an item can have at
most one value (like `name` or `notes`) and there are fields where an
item can have multiple values (like `tag`). At last there are special
fields that are either implemented directly using custom sql or that
are only shortcuts to a longer form.

Here is the list of all available fields.

These fields map to at most one value:

- `name` the item name
- `source` the source used for uploading
- `notes` the item notes
- `id` the item id
- `date` the item date
- `due` the due date of the item
- `created` the date when the item was created
- `attach.count` the number of attachments of the item
- `corr.org.id` the id of the correspondent organization
- `corr.org.name` the name of the correspondent organization
- `corr.pers.name` name of correspondent person
- `corr.pers.id` id of correspondent person
- `conc.pers.name` name of concerning person
- `conc.pers.id` id of concerning person
- `conc.equip.name` name of equipment
- `conc.equip.id` id of equipment
- `folder.id` id of a folder
- `folder` name of a folder
- `inbox` whether to return "new" items (boolean)
- `incoming` whether to return incoming items (boolean), `true` to
  show only incoming, `false` to show only outgoing.

These fields support all operators, except `incoming` and `inbox`
which expect boolean values and for those some operators don't make
sense.

Fields that map to more than one value:

- `tag` the tag name
- `tag.id` the tag id
- `cat` name of the tag category

The tag and category fields use two operators: `:` and `=`.

Other special fields:

- `attach.id` references the id of an attachment
- `checksum` references the sha256 checksum of a file
- `content` for fulltext search
- `f` for referencing custom fields by name
- `f.id` for referencing custom fields by their id
- `dateIn` a shortcut for a range search
- `dueIn` a shortcut for a range search
- `createdIn` a shortcut for a range search
- `exist` check if some porperty exists
- `names` a shortcut to search in several names via `:`
- `year` a shortcut for a year range
- `conc` a shortcut for concerning person and equipment names
- `corr` a shortcut for correspondent org and person names

These fields are often using the `:` operator to simply separate field
and value. They are often backed by a custom implementation, or they
are shortcuts for a longer query.

## Values

Values are the data you want to search for. There are different kinds
of that, too: there are text values, numbers, boolean and dates. When
multiple values are allowed, they must be separated by comma `,`.

### Text Values

Text values need to be put in quotes (`"`) if they contain one of
these characters:
- whitespace ` `
- quotes `"`
- backslash `\`
- comma `,`
- brackets `[]`
- parens `()`

Any quotes inside a quoted string must be escaped with a backslash.

Examples: `scan_123`, `a-b-c`, `x.y.z`, `"scan from today"`, `"a \"strange\"
name.pdf"`

### Numeric and Boolean Values

Numeric values can be entered literally; an optional fraction part is
separetd by a dot. Examples: `1`, `2.15`.

A boolean value can be specfied by `yes` or `true` and `no` or
`false`, respectively. Example: `inbox:yes`

### Dates

Dates are always treated as local dates and can be entered in multiple
ways.

#### Date Pattern

They can be in the following form: `YYYY-MM-DD` or `YYYY/MM/DD`.
The month and day part are optional; if they are missing they are
filled automatically with a `1`. So `2020-01` would be the same as
`2020-01-01`.

A special pattern is `today` which marks the current day.

#### Unix Epoch

Dates can be given in milliseconds from unix epoch. Then it must be
prefixed by `ms`. The time part is ignored. Examples:
`ms1615209591627`.

#### Calculation

Dates can be defined by providing a base date via the forms above and
a period to add or substract. This is especially useful with the
`today` pattern. The period must be separated from the date by a
semi-colon `;`. Then write a `+` or a `-` to add or substract and at
last the number of days (suffix `d`) or months (suffix `m`).

Examples: `today;-14d`, `2020-02;+1m`


# Simple Expressions

Simple expressions are made up of a field with at most one value, an
operator and one or more values. These fields support all operators,
except for boolean fields.

The like operator `:` can be used with all values, but makes only
sense for text values. It allows to do a substring search for a field.

For example, this looks for an item with a name of exactly
'invoice_22':

```
name=invoice_22
```

By using `:`, it is possible to look for items that have 'invoice'
somewhere in their name:

```
name:*invoice*
```

The asterisk `*` can be added at the beginning and/or end of the
value, but not in betwee. Furthermore, the like operator is
case-insensitive, whereas `=` is not. This applies to all fields with
a text value.

This is another example looking for a correspondent person of with
'marcus' in the name:

```
corr.pers.name:*marcus*
```


----

Comparisons via `<`/`>` are done alphanumerically for text based
values and numerically for numeric values. For booleans these
operators don't make sense and therefore don't work there.

----

All these fields (except boolean fields) allow to use the in-operator,
`~=`. This is a more efficient form to specify a list of alternative
values for the same field. It is logically the same as combining
multiple expressions with `OR`. For example:

```
source~=webapp,mailbox
```

is the same as
```
(| source=webapp source=mailbox )
```

The `~=` version is nicer to read, safes some key strokes and also
runs more efficient when the list grows. It is *not* possible to use a
wildcard `*` here. If a wildcard is required, you need to write the
longer form.

If one value contains whitespace or other characters that require
quoting, each value must be quoted, not the whole list. So this is
correct:
```
source~="web app","mail box"
```

This is not correct: `source~="web app,mail box"` – it would be treated
as one single value and is then essentially the same as using `=`.

----

The two fields `incoming` and `inbox` expect a boolean value: one of
`true` or `false`. The synonyms `yes` and `no` can also be used to
make it better readable.

This finds all items that have not been confirmed:
```
inbox:yes
```

The `incoming` can be used to show only incoming or only outgoing
documents:

```
incoming:yes
```

For outgoing, you need to say:
```
incoming:no
```


# Tags

Tags have their own syntax, because they can appear multiple times on
an item. Tags only allow for two operators: `=` and `:`. Combined with
negation (the `!` operator), this is quite flexible.

For tags, `=` means that items must have *all* specified tags (or
more), while `:` means that items must have at least *one* of the
specified tags. Tags can be identified by their name or id and are
given as a comma separated list (just like when using the
in-operator).

Some examples: Find all invoices that are todo:

```
tag=invoice,todo
```

This returns all items that have both tags `invoice` and `todo`.
Negating this:

```
!tag=invoice,todo
```

… results in an expression that returns all items that don't have
*both* tags. It might return items with tag `invoice` and also items
with tag `todo`, but no items that have both of them.

Using `:` is just analog to `=`. This finds all items that are either
`waiting` or `todo` (or both):

```
tag:waiting,todo
```

When negating this:
```
!tag:waiting,todo
```

it finds all items that have *none* of the tags.

Tag names are always compared case-insensitive. Tags can also be
selected using their id, then the field name `tag.id` must be used
instead of `tag`.

The field `cat` can be used the same way to search for tag categories.


# Custom Fields

Custom fields can be used via the following syntax:

```
f:<field-name><operator><value>
```

They look almost like a simple expression, only prefixed with a `f:`
to indicate that the following is the name of a custom field.

The type of a custom field is honored. So if you have a money or
numeric type, comparsions are done numerically. Otherwise a
alphnumeric comparison is performed. Custom fields do not support the
in-operator (`~=`).

For example: assuming there is a custom field of type *money* and name
*usd*, the following selects all items with an amount between 10 and
150:

```
f:usd>10 f:usd<150
```

The like-operator can be used, too. For example, to find all items
that have a custom field `asn` (often used for a serial number printed
on the document):

```
f:asn:*
```

If the like operator is used on numeric fields, it falls back to
text-comparison.

Instead of using the name, the field-id can be used to select a field.
Then the prefix is `f.id`:

```
f.id:J2ES1Z4Ni9W-xw1VdFbt3KA-rL725kuyVzh-7La95Yw7Ax2:15.00
```


# Fulltext Search

The special field `content` allows to add a fulltext search. Using
this is currently restricted: it must occur in the root (AND) query
and cannot be nested in other complex expressions.

The form is:

```
content:<your search query>
```

The search query is interpreted by the fulltext index (currently it is
SOLR). This is usually very powerful and in many cases this value must
be quoted.

For example, do a fulltext search for 'red needle':
```
content:"red needle"
```

It can be combined in an AND expression:

```
content:"red needle" tag:todo
```

But it can't be combined via OR. This is not possible:

```
tag:todo (| content:"red needle" tag:waiting)
```



# File Checksums

The `checksum` field can be used to look for items that have a certain
file attached. It expects a SHA256 string.

For example, this is the sha256 checksum of some file on the hard
disk:
`40675c22ab035b8a4ffe760732b65e5f1d452c59b44d3d0a2a08a95d28853497`.

To find all items that have (exactly) this file attached:
```
checksum:40675c22ab035b8a4ffe760732b65e5f1d452c59b44d3d0a2a08a95d28853497
```

# Exist

The `exist` field can be used with another field, to check whether an
item has some value for it. It only works for fields that have at most
one value.

For example, it could be used to find items that are in any folder:

```
exist:folder
```

When negating, it finds all items that are not in a folder:

```
!exist:folder
```


# Attach-Id

The `attach.id` field is a special field to find items by providing
the id of an attachment. This can be helpful in certain situations
when you only have the id or part of that of an attachment. It uses
equality if no wildcard is present. A wildcard `*` can be used at
beginning or end if only a part of the id is known.

```
attach.id=5YjdnuTAdKJ-V6ofWTYsqKV-mAwB5aXTNWE-FAbeRU58qLb
attach.id=5YjdnuTAdKJ*
```


# Shortcuts

Shortcuts are only a short form of a longer query and are provided for
convenience. The following exist:

- `dateIn`, `dueIn` and `createdIn`
- `year`
- `names`
- `conc`
- `corr`


### Date Ranges

The first three are all short forms to specify a range search. With
`dateIn` and `dueIn` have three forms that are translated into a range
search:

- `dateIn:2020-01;+15d`  →  `date>=2020-01 date<2020-01;+15d`
- `dateIn:2020-01;-15d`  →  `date>=2020-01;-15d date<2020-01`
- `dateIn:2020-01;/15d`  →  `date>=2020-01;-15d date<2020-01;+15d`

The syntax is the same as defining a date by adding a period to some
base date. These two dates are used to expand the form into a range
search. There is an additional `/` character to allow to subtract and
add the period.

The `year` is almost the same thing, only a lot shorter to write. It
expands into a range search (only for the item date!) that selects all
items with a date in the specified year:

- `year:2020`  →  `date>=2020-01-01 date<2021-01-01`

The last shortcut is `names`. It allows to search in many "names" of
related entities at once:

### Names

- `names:tim` → `(| name:tim corr.org.name:tim corr.pers.name:tim conc.pers.name:tim conc.equip.name:tim )`

The `names` field uses the like-operator.

The fields `conc` and `corr` are analog to `names`, only that they
look into correspondent names and concerning names.

- `conc:marc*` → `(| conc.pers.name:marc* conc.equip.name:marc* )`
- `corr:marc*` → `(| corr.org.name:marc* corr.pers.name:marc* )`


# Examples

Find items with 2 or more attachments:
```
attach.count>2
```

Find items with at least one tag invoice or todo that are due next:
```
tag:invoice,todo due>today
```

Find items with at least both tags invoice and todo:
```
tag=invoice,todo
```

Find items with a concerning person of name starting with "Marcus":
```
conc.pers.name:marcus*
```

Find items with at least a tag "todo" in year 2020:
```
tag:todo year:2020
```

Find items within the last 30 days:
```
date>today;-30d
```

Find items with a custom field `paid` set to any value:
```
f:paid:*
```

Find items that have been paid with more than $100 (using custom
fields `paid` as a date and `usd` as money):
```
f:paid:* f:usd>100
```
