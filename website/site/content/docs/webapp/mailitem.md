+++
title = "Send items via E-Mail"
weight = 50
[extra]
mktoc = true
+++

You can send e-mails from within docspell attaching the files of an
item. This is useful to collaborate or share certain documents with
people outside docspell.

All sent mails are stored attached to the item.


## E-Mail Settings (SMTP)

To send mails, there are SMTP settings required. Please see the page
about [e-mail settings](@/docs/webapp/emailsettings.md#smtp-settings).


## Sending Mails

Currently, it is possible to send mails related to only one item. You
can define the mail body and docspell will add the attachments of an
item, or you may choose to send the mail without any attachments.

In the item detail view, click on the envelope icon to open the mail
form:

{{ figure(file="mail-item-1.jpg") }}

Then write the mail. Multiple recipients may be specified. The input
field shows completion proposals from all contacts in your address
book (from organizations and persons). Choose an address by pressing
*Enter* or by clicking a proposal from the list. The proposal list can
be iterated by the *Up* and *Down* arrows. You can type in any
address, of course, it doesn't need to match a proposal.

If you have multiple mail settings defined, you can choose in the top
dropdown which account to use for sending.

The last checkbox allows to choose whether docspell should add all
attachments of the item to the mail. If it is unchecked, no
attachments will be added. It is currently not possible to pick
specific attachments, it's all or nothing.

Clicking *Cancel* will delete the inputs and close the mail form, but
clicking the envelope icon again, will only close the form without
clearing its contents.

The *Send* button is active once all input fields have been filled.
Once you click *Send*, the docspell server will send the mail using
your connection settings. If that succeeds the mail is saved to the
database and you'll see a message in the form.

## Accessing Sent Mails

If there is an e-mail for an item, a tab shows up at the right side,
next to the attachments.

{{ figure(file="mail-item-2.jpg") }}

This tab shows a list of all mails that have been sent related to this
item.

{{ figure(file="mail-item-3.jpg") }}

Clicking on a mail opens it in detail.

{{ figure(file="mail-item-4.jpg") }}
