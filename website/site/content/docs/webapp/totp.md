+++
title = "Two-Factor Authentication"
weight = 110
[extra]
mktoc = true
+++

# TOTP

Docspell has built-in support for two-factor (2FA) authentication
using
[TOTP](https://en.wikipedia.org/wiki/Time-based_One-Time_Password)s.
For anything more, consider a dedicated account management tool and
[OpenID Connect](@/docs/configure/_index.md#openid-connect-oauth2).

## Setup

A user can enable a TOTP as a second factor in their user settings. It
is required to have some external device to hold the shared secret. A
popular way is using your phone.

In user settings, go to _Two Factor Authentication_ and click on
_Activate two-factor authentication_. This then shows you a QR code:

{{ figure2(light="totp-01.png", dark="totp-01_dark.png") }}

Open the app (or whatever you use) and scan the QR code. A new account
is created and a 6-digit code will be shown to you. Enter this code in
the box below to confirm.

If you cannot scan the QR code, click on the "eye icon" to reveal the
secret that you then need to type/copy. This secret will never be
shown again. Should you loose it (or your device where it is saved),
you cannot log in anymore. See below for how to get into your account
in this case.

Once you typed in the code, the 2FA is enabled.

{{ figure2(light="totp-02.png", dark="totp-02_dark.png") }}

When you now login, a second login form will be shown where you must
now enter a one time password from the device.

## Remove 2FA

If you go to this page with 2FA enabled (refresh the page after
finishing the setup), you can disable it. The secret will be removed
from the database.

It shows a form that allows you to disable 2FA again, but requires you
to enter a one time password.

{{ figure2(light="totp-03.png", dark="totp-03_dark.png") }}

If you have successfully disabled 2FA, you'll see the first screen
where you can activate 2FA. You can remove the account from your
device. Should you want to go back to 2FA, you need to go through the
setup again and create a new secret.

## When secret is lost

Should you loose your device where the secret is stored, you cannot
log into docspell anymore. In this case you can use the [command line
client](@/docs/tools/cli.md) to execute an admin command that removes
2FA for a given user.

For this to work, you need to [enable the admin
endpoint](@/docs/configure/_index.md#admin-endpoint). Then execute the
`disable-2fa` admin command and specify the complete account.

```
$ dsc admin -a test123 disable-2fa --account demo
┌─────────┬──────────────────────┐
│ success │ message              │
├─────────┼──────────────────────┤
│ true    │ TOTP setup disabled. │
└─────────┴──────────────────────┘
```
