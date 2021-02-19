+++
title = "Multi Edit"
weight = 25
+++

Docspell allows to edit and delete multiple items at once.

## Toggle Selection Mode

Search the items you want to edit or delete and then select them by
changing into "select mode". This changes the view slightly by
changing the menu to the main area and the item cards have a dashed
border:

{{ figure(file="multiedit-01.png") }}

Then select items by clicking on the card. You can also change the
search form and add more items to the selection. The top left shows
how many items are selected and allows to select and deselect all
visible items. Selected items are displayed grey-ed out with a big
check icon. Clicking this icon deselects the item.

{{ figure(file="multiedit-02.png") }}


## Choose an Action: Edit

Once all desired items are selected, choose an action. Currently you
can edit or delete them. When clicking "edit", the left side menu
changes to a form for changing the metadata:

{{ figure(file="multiedit-03.png") }}

Changing the metadata in that form immediately applies it to all
selected items. You can change the selection anytime.

{{ figure(file="multiedit-04.png") }}


If you are done, just click on the *Close* button or the icon from the
beginning to go back to "normal" mode.


### Tags

Tags are a bit special, because they can hold multiple values.
Therefore the tag field can work in three modes:

1. _Add-Mode_ all tags you select are added to the items (the default)
2. _Remove-Mode_ all tags you select are removed from the items
3. _Replace-Mode_ all tags you select are being replaced on the items
   (existing tags are removed, before adding selected tags)

You can change the modes using the small icon above the tag input
field (on the right).


## Choose an Action: Delete

When choosing the delete action, a confirmation dialog shows up. If
you confirm the deletion, then all selected items are deleted at the
server and the view is switched back to normal mode afterwards. Note
that deleting a lot of items may take a while to finish.

{{ figure(file="multiedit-06.png") }}
