---
layout: docs
title: Send items via E-Mail
---

# {{page.title}}

You can send e-mails from within docspell attaching the files of an
item. This is useful to collaborate or share certain documents with
people outside docspell.

All sent mails are stored attached to the item.


## E-Mail Settings

To send mails, there are SMTP settings required. Since an e-mail
account is connected to a user, you need to check the *User Settings*
page from the top-right menu.

<div class="thumbnail">
  <img src="../img/mail-settings-1.jpg">
</div>

First, you need to provide some name that is used to recognize this
account. This name is also used in URLs to docspell and so it must not
contain whitespace or any special characters. A good value is the
domain of your provider, for example `gmail.com`, or something like
that.

These information should be available from your e-mail provider. For
example, for google-mail it is:

- SMTP Host: `smtp.gmail.com`
- SMTP Port: `587` or `465`
- SMTP User: Your Gmail address (for example, example@gmail.com)
- SMTP Password: Your Gmail password
- SSL: use `SSL` for port `465` and `StartSSL` for port `587`

Then you need to define the e-mail address that is used for the `From`
field. This is in most cases the same address as used for the SMTP
User field.

The `Reply-To` field is optional and can be set to define a different
e-mail address that your recipients should use to answer a mail.

Once this is setup, you can start sending mails within docspell. It is
possible to set up these settings for multiple providers, so you can
choose from which account you want to send mails.


*Please Note: If `SSL` is set to `None`, then mails will be sent
unencrypted to your mail provider! If `Ignore certificate check` is
enabled, connections to your mail provider will succeed even if the
provider is wrongly configured for SSL/TLS. This flag should only be
enabled if you know why.*

## Sending Mails

Currently, it is possible to send mails related to only one item. You
can define the mail body and docspell will add the attachments of an
item, or you may choose to send the mail without any attachments.

In the item detail view, click on the envelope icon to open the mail
form:

<div class="thumbnail">
  <img src="../img/mail-item-1.jpg">
</div>

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


<div class="thumbnail">
  <img src="../img/mail-item-2.jpg">
</div>

This tab shows a list of all mails that have been sent related to this
item.

<div class="thumbnail">
  <img src="../img/mail-item-3.jpg">
</div>

Clicking on a mail opens it in detail.

<div class="thumbnail">
  <img src="../img/mail-item-4.jpg">
</div>
