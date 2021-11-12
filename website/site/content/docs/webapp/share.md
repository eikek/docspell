+++
title = "Shares"
weight = 120
[extra]
mktoc = true
+++

Docspell has a thought-out share feature that allows you to create
read-only views to a subset of your documents and create a public but
not-guessable link to it.

# Concept

A share is a cryptic *share id* that maps to a
[query](@/docs/query/_index.md). A share can be accessed via a public
link that contains the share id.

{% infobubble(mode="warning", title="Please note") %}

Everyone who has this link can access all documents resulting from the
query and their metadata.

{% end %}

To further protect this link, a password can be specified which should
be distributed via a different channel than the link. If a password is
defined for a share, it is required to access the items. Otherwise,
the share id is all that's needed.

A share also requires to set a *publication end date* as a protection
for leaving links available forever. Of course, you can explicitely
set it to a very far away date should you really want it.

The query is executed under the user who created the share. Thus it
returns all the items the user can see. This is important when you
have folders that are only visible to you. If you don't want to share
certain items, you must alter the query accordingly.

Given the nature of a query, there are two kinds of shares possible:
dynamic and static ones. A dynamic share uses a query that may yield
different results over time, for example `tag:invoice`. A static query
is a query that explicitely selects items by their id. This means the
latter will always result in the selected items (except if one of them
is deleted); whereas the former query could return different results
each time it is executed, because new documents could have been added
in the meantime that now match the criteria (like tagged with
`invoice` in the example).

A share can be enabled and disabled to quickly make it available or
hidden.


## Use Cases

A useful application for shares is to have a simple view to documents
that are not sensible, like manuals. You could create a share for all
your manuals, for example using tags `tags:manual` and bookmark it.

Another use case is to share sensible documents with a partner who
needs access to it, for example if you want to share all your tax
documents with the company/person who helps you with doing you tax
submission.

## Limitations

Currently, shares that contain fulltext search queries are not
supported. The query for a share must not use any fulltext search.

# Creating shares

There are the following ways to create a share:

1. From the search page: enter a query or use the search menu and then
   click the *share* button to share the resulting documents. This
   usually creates a dynamic share.
2. From selecting items: In the search view, click *Select Mode* and
   select a few items. Then click the *share* button to share exactly
   these items. This will create a static share.
3. By creating it manually: You can also go to *Collective Profile*
   and create a new share using the provided form.

Once you created the share, you can copy the url or send it via e-mail
(requires to have [e-mail
settings](@/docs/webapp/emailsettings.md#smtp-settings) defined).

## Creating from search results

When at the search page, add some criteria until you have the results
you want to publish. In the screenshot below all items with tag
`Manual` are selected. Then click the *Share Button*.

{{ figure(file="share-01.png") }}

A form appears that lets you edit the query and set some properties.
The query is taken from the search page and may look a bit strange. It
will use ids rather than names, which makes the query a bit more
robust. For example: the query `tag=manual` also works, but should you
rename the tag, the share won't work anymore. By using ids as in
`tag.id=4AUye…`, the query is immune to renamings.

A name can be given to make it better distinguishable from other
shares. Then a password and the *Publish Until* date can be set. The
*Publish Until* date is mandatory. You can set it to something very
far away to have shares exist "forever".

{{ figure(file="share-02.png") }}

Clicking *Cancel* brings you back to the search results. If you are
satifsied, click *Publish*. The next screen allows you to inspect your
new share and to copy the url and/or send an e-mail. The email form is
prefilled with some template that contains the link, so you don't need
to copy it.

{{ figure(file="share-03.png") }}

When typing in an e-mail address, there are completion proposals
provided from your address book. If you type in an arbitrary address
(not in the proposals), hit *Enter* or *Space* in order to add the
current address. You can hit *Backspace* two times to remove the last
e-mail address.

The new share can now be found in *Collective Profile -> Shares*.
Clicking *Done* brings you back to the search results.

## Creating from selecting items

Creating a share for a hand picked set of items is almost the same as
the above. In the search page, go to *Select Mode* and select some
items.

{{ figure(file="share-04.png") }}

Then click the *Share* button and follow the same process as described
above. The query selects now exactly the picked items like in
`id~=AhVX…,FG65Xy…`.


## Creating manually

At *Collective Profile -> Shares* there is a *New share* button, which
will present a form where you can create a share. The query must then
be filled manually (there is some syntax help). It is the same query
as in the "power search" bar, as described
[here](@/docs/query/_index.md).

{{ figure(file="share-12.png") }}

## Managing Shares

Go to *Collective Profile -> Shares* to see all the shares of your
collective. You can also look into shares that were created by other
users.

{{ figure(file="share-06.png") }}

To not make it too easy to look into private folders, you cannot
change attributes of shares that were created by another user.
However, you can delete all shares. This is for now a compromise,
assuming small groups that still talk to each other: All users of a
collective are equal and should be able to see shares and also delete
them. But since a share of another user could be used to easily look
into folders where you are not a member, editing other shares is not
allowed.

If you edit your own share, you can change its properties.

{{ figure(file="share-07.png") }}

If you are not the owner, the form is hidden:

{{ figure(file="share-08.png") }}


# Accessing a share

Pasting the share link into a browser shows you the results of the
query:

{{ figure(file="share-09.png") }}

The search input allows to do a fulltext search and the search menu to
the left can be used to further constrain the results. The search will
be combined with the stored query, such that the results always remain
within the original results of the share.

The options in the dropdown menus for correspondent, concerning etc
are taken from the results. So only the data that is shared by the
search results will be available to select. Other data is not leaked.

Clicking the search icon next to the search input, switches the input
to be the "power search" input:

{{ figure(file="share-11.png") }}

There is a link below the input field that opens a new tab with the
[query documentation page](@/docs/query/_index.md).

The user can click on the tags and other data in the item cards which
will populate the corresponding section in the search menu, just like
the default search view. You can click on an item card to go to the
detail view:

{{ figure(file="share-10.png") }}

This link to a single item is also bookmarkable. You can copy it via
the QR code or by clicking the *Copy* button. In the detail view you
can select multiple attachments and download each.
