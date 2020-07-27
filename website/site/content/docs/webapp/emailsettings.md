+++
title = "E-Mail Settings"
weight = 40
[extra]
mktoc = true
+++

Docspell has a good integration for E-Mail. You can send e-mails
related to an item and you can import e-mails from your mailbox into
docspell.

This requires to define settings to use for sending and receiving
e-mails. E-Mails are commonly send via
[SMTP](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol)
and for receiving
[IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol)
is quite common. Docspell has support for SMTP and IMAP. These
settings are associated to a user, so that each user can specify its
own settings separately from others in the collective.

*Note: Passwords to your e-mail accounts are stored in plain-text in
docspell's database. This is necessary to have docspell connect to
your e-mail account to send mails on behalf of you and receive your
mails.*


## SMTP Settings

For sending mail, you need to provide information to connect to a SMTP
server. Every e-mail provider has this information somewhere
available.

Configure this in *User Settings -> E-Mail Settings (SMTP)*:

{{ figure(file="mail-settings-1.png") }}

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


## IMAP Settings

For receiving e-mails, you need to provide information to connect to
an IMAP server. Your e-mail provider should have this information
somewhere available.

Configure this in *User Settings -> E-Mail Settings (IMAP)*:

{{ figure(file="mail-settings-2.png") }}

First you need to define a *Name* to recognize this connection inside
docspell. This name is also used in URLs to docspell and so it must
not contain whitespace or any special characters. A good value is the
domain of your provider, for example `gmail.com`, or something like
that.

You can provide imap connections to multiple mailboxes.

Here is an example for posteo.de:

- IMAP Server: `posteo.de`
- IMAP Port: 143
- IMAP User: Your posteo address
- IMAP Password: Your posteo password
- SSL: use `StartTLS`


## SSL / TLS / StartTLS

*Please Note: If `SSL` is set to `None`, then mails will be sent
unencrypted to your mail provider! If `Ignore certificate check` is
enabled, connections to your mail provider will succeed even if the
provider is wrongly configured for SSL/TLS. This flag should only be
enabled if you know why.*


## GMail

Authenticating with GMail may be not so simple. GMail implements an
authentication scheme called *XOAUTH2* (at least for Imap). It will
not work with your normal password. This is to avoid giving an
application full access to your gmail account.

The e-mail integration in docspell relies on the
[JavaMail](https://javaee.github.io/javamail) library which has
support for XOAUTH2. It also has documentation on what you need to do
on your gmail account: <https://javaee.github.io/javamail/OAuth2>.

First you need to go to the [Google Developers
Console](https://console.developers.google.com) and create an "App" to
get a Client-Id and a Client-Secret. This "App" will be your instance
of docspell. You tell google that this app may send and read your
mails and then you get an *access token* that should be used instead
of the password.

Once you setup an App in Google Developers Console, you get the
Client-Id and the Client-Secret, which look something like this:

- Client-Id: 106701....d8c.apps.googleusercontent.com
- Client-Secret: 5Z1...Kir_t

Google has a python tool to help with getting this access token.
Download the `oauth2.py` script from
[here](https://github.com/google/gmail-oauth2-tools) and first create
an *oauth2-token*:

``` bash
./oauth2.py --user=your.name@gmail.com \
   --client_id=106701....d8c.apps.googleusercontent.com \
   --client_secret=5Z1...Kir_t \
   --generate_oauth2_token
```

This will "redirect you" to an URL where you have to authenticate with
google. Afterwards it lets you add permissions to the app for
accessing your mail account. The result is another code you need to
give to the script to proceed:

```
4/zwE....q0QBAb-99yD7lw
```

Then the scripts produces this:

```
Refresh Token: 1//09zH.........Lj6oc2SmFlZww
Access Token: ya29.a0........SECDQ
Access Token Expiration Seconds: 3599
```

The access token can be used to sign in via IMAP with google. The
Refresh Token doesn't expire and can be used to generate new access
tokens:

```
./oauth2.py --user=your.name@gmail.com \
   --client_id=106701....d8c.apps.googleusercontent.com \
   --client_secret=5Z1...Kir_t \
   --refresh_token=1//09zH.........Lj6oc2SmFlZww
```

Output:
```
Access Token: ya29.a0....._q-lX3ypntk3ln0h9Yk
Access Token Expiration Seconds: 3599
```

The problem is that the access token expires. Docspell doesn't support
updating the access token. It could be worked around by setting up a
cron-job or similiar which uses the `oauth2.py` tool to generate new
access tokens and update your imap settings via a
[REST](@/docs/api/_index.md) call.

``` bash
#!/usr/bin/env bash
set -e

## Change this to your values:

DOCSPELL_USER="[docspell-user]"
DOCSPELL_PASSWORD="[docspell-password]"
DOCSPELL_URL="http://localhost:7880"
DOCSPELL_IMAP_NAME="gmail.com"

GMAIL_USER="your.name@gmail.com"
CLIENT_ID="106701....d8c.apps.googleusercontent.com"
CLIENT_SECRET="secret=5Z1...Kir_t"
REFRESH_TOKEN="1//09zH.........Lj6oc2SmFlZww"
# Path to the oauth2.py tool
OAUTH_TOOL="./oauth2.py"

##############################################################################
## Script


# Login to docspell and store the auth-token
AUTH_DATA=$(curl --silent -XPOST \
                 -H 'Content-Type: application/json' \
                 --data-binary "{\"account\":\"$DOCSPELL_USER\",\"password\":\"$DOCSPELL_PASSWORD\"}" \
                 $DOCSPELL_URL/api/v1/open/auth/login)
if [ $(echo $AUTH_DATA | jq .success) == "false" ]; then
    echo "Auth failed"
    echo $AUTH_DATA
fi
TOKEN="$(echo $AUTH_DATA | jq -r .token)"


# Get the imap settings
UPDATE_URL="$DOCSPELL_URL/api/v1/sec/email/settings/imap/$DOCSPELL_IMAP_NAME"
IMAP_DATA=$(curl -s -H "X-Docspell-Auth: $TOKEN" "$UPDATE_URL")

echo "Current Settings:"
echo $IMAP_DATA | jq


# Get the new access token
ACCESS_TOKEN=$($OAUTH_TOOL --user=$GMAIL_USER \
    --client_id="$CLIENT_ID" \
    --client_secret="$CLIENT_SECRET" \
    --refresh_token="$REFRESH_TOKEN" | head -n1 | cut -d':' -f2 | xargs)

# Update settings
echo "Updating IMAP settings"
NEW_IMAP=$(echo $IMAP_DATA | jq ".imapPassword |= \"$ACCESS_TOKEN\"")
curl -s -XPUT -H "X-Docspell-Auth: $TOKEN" \
     -H 'Content-Type: application/json' \
     --data-binary "$NEW_IMAP" "$UPDATE_URL"
echo
echo "New Settings:"
curl -s -H "X-Docspell-Auth: $TOKEN" "$UPDATE_URL" | jq
```
