+++
title = "Merge Items"
weight = 100
[extra]
mktoc = true
+++

# Merge Items

Merging multiple items into one lets you transfer metadata and
attachments from multiple items into a single one. The items that have
been merged are removed afterwards.

## Usage
### Select items to merge

Multiple items can be merged where all metadata is copied into the
target item. This can be done by selecting multiple items to merge via
the multi selection tool as described
[here](@/docs/webapp/multiedit.md#toggle-selection-mode).

Then select some items (at least 2) and click the merge tool button.

{{ figure2(light="merge-01.png", dark="merge-01_dark.png") }}


### Edit order of items

This opens the merge view, where you can change the order of the
selected items.

{{ figure2(light="merge-02.png", dark="merge-02_dark.png") }}

The order of this list can matter when merging (see below). You can
move items via drag and drop or the buttons on the right.


### Click merge

Once you clicke the *Merge* button, the items are merged and you will
be taken to the search view.

{{ figure2(light="merge-04.png", dark="merge-04_dark.png") }}

As you can see, tags are all combined. Custom fields of same name are
also merged, where possible. For text fields, the values are
concatenated with a comma as separator. Money and numeric fields are
simply added together. Also it shows that there are now two
attachments in the item.


# How it works

Since the metadata of all items are merged into one, the order matters
for fields that allow only one value (for example correspondents,
concerning person/equipment, folder and dates). For these fields, the
value of the first item in the list is used. The exception is the item
notes: they are all concatenated with some newlines in between.

All properties that allow multiple values (like tags and the
attachments, of course) are simply moved to the target item. Custom
fields are merged depending on their type. Fields of type money and
numeric are added together such that the final item contains the sum
of all values. Text fields are concatenated using a comma as
separator. Other fields (boolean and date) are again chosen from the
first item that has a value.

After merging, the other items are removed from the database (they
cannot be restored). This reason is that many data is moved into the
target item and so the remaining items are actually empty.
