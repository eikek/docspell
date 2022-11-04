+++
title = "Authentication"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 70
template = "docs.html"
+++

## Authentication

Authentication works in two ways:

- with an account-name / password pair
- with an authentication token

The initial authentication must occur with an accountname/password
pair. This will generate an authentication token which is valid for a
some time. Subsequent calls to secured routes can use this token. The
token can be given as a normal http header or via a cookie header.

These settings apply only to the REST server.

``` bash
docspell.server.auth {
  server-secret = "hex:caffee" # or "b64:Y2FmZmVlCg=="
  session-valid = "5 minutes"
}
```

The `server-secret` is used to sign the token. If multiple REST
servers are deployed, all must share the same server secret. Otherwise
tokens from one instance are not valid on another instance. The secret
can be given as Base64 encoded string or in hex form. Use the prefix
`hex:` and `b64:`, respectively. If no prefix is given, the UTF8 bytes
of the string are used.

The `session-valid` determines how long a token is valid. This can be
just some minutes, the web application obtains new ones
periodically. So a rather short time is recommended.

## OpenID Connect / OAuth2

You can integrate Docspell into your SSO solution via [OpenID
Connect](https://openid.net/connect/) (OIDC). This requires to set up
an OpenID Provider (OP) somewhere and to configure Docspell
accordingly to act as the relying party.

You can define multiple OPs to use. For some examples, please see the
[default configuration](@/docs/configure/defaults.md).

The configuration of a provider highly depends on how it is setup.
Here is an example for a setup using
[keycloak](https://www.keycloak.org):

``` conf
provider = {
  provider-id = "keycloak",
  client-id = "docspell",
  client-secret = "example-secret-439e-bf06-911e4cdd56a6",
  scope = "profile", # scope is required for OIDC
  authorize-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/auth",
  token-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/token",
  #User URL is not used when signature key is set.
  #user-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/userinfo",
  #logout-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/logout?redirect_uri=…"
  sign-key = "b64:MII…ZYL09vAwLn8EAcSkCAwEAAQ==",
  sig-algo = "RS512"
}
```

The `provider-id` is some identifier that is used in the URL to
distinguish between possibly multiple providers. The `client-id` and
`client-secret` define the two parameters required for a "confidential
client". The different URLs are best explained at the [keycloak
docs](https://www.keycloak.org/docs/latest/server_admin/).
They are available for all OPs in some way. The `user-url` is not
required, if the access token is already containing the necessary
data. If not, then docspell performs another request to the
`user-url`, which must be the user-info endpoint, to obtain the
required user data.

The `logout-url` is optional. If specified the browser will be
redirected to this url when a user logsout from Docspell. It should
then logout the user from the authentication provider as well. If not
given, the user is logged out from Docspell, but may still hold a SSO
session. In this case a warning is rendered on the login screen.
*Note that this currently only applies if `oidc-auto-redirect=true`.*

If the data is taken from the token directly and not via a request to
the user-info endpoint, then the token must be validated using the
given `sign-key` and `sig-algo`. These two values are then required to
specify! However, if the user-info endpoint should be used, then leave
the `sign-key` empty and specify the correct url in `user-url`. When
specifying the `sign-key` use a prefix of `b64:` if it is Base64
encoded or `hex:` if it is hex encoded. Otherwise the unicode bytes
are used, which is most probably not wanted for this setting.

Once the user is authenticated, docspell tries to setup an account and
does some checks. For this it must get to the username and collective
name somehow. How it does this, can be specified by the `user-key` and
`collective-key` settings:

``` conf
# The collective of the user is given in the access token as
# property `docspell_collective`.
collective-key = "lookup:docspell_collective",
# The username to use for the docspell account
user-key = "preferred_username"
```

The `user-key` is some string that is used to search the JSON response
from the OP for an object with that key. The search happens
recursively, so the field can be in a nested object. The found value
is used as the user name. Keycloak transmits the `preferred_username`
when asking for the `profile` scope. This can be used as the user
name.

The collective name can be obtained by different ways. For example,
you can instruct your OP (like keycloak) to provide a collective name
in the token and/or user-info responses. If you do this, then use the
`lookup:` prefix as in the example above. This instructs docspell to
search for a value the same way as the `user-key`. You can also set a
fixed collective, using `fixed:` prefix; in this case all users are in
the same collective! A third option is to prefix it with `account:` -
then the value that is looked up is interpreted as the full account
name, like `collective/user` and the `user-key` setting is ignored. If
you want to put each user in its own collective, you can just use the
same value as in `user-key`, only prefixed with `lookup:`. In the
example it would be `lookup:preferred_username`.

If you find that these methods do not suffice for your case, please
open an issue.

### Auto-redirect to the OIDC provider

If there is only one single configured openid provider and this
setting:

```
oidc-auto-redirect = true
```

Then the webui will redirect immediately to the login page of the oidc
provider, skipping the login page for Docspell.

For logging out, you can specify a `logout-url` for the provider which
is used to redirect the browser after logging out from Docspell.

## Mixing OIDC and local accounts

Local accounts and those created from an openid provider can live next
to each other. There is only a caveat for accounts with same login
name that may occur from local and openid providers. By default,
docspell treats OIDC and local accounts always as different when
logging in.

That means when a local user exists and the same account is trying to
login via an openid provider, docspell fails the authentication
attempt by default. It could be that these accounts belong to
different persons in reality.

The other way around is the same: signing up an account that exists
due to an OIDC login doesn't work, because the collective already
exists. And obviously, logging in without a password doesn't work
either :). Even if a password would exists for an account created by
an OIDC flow, logging in with it doesn't work. It would allow to
bypass the openid provider (which may not be desired)

This behavior can be changed by setting:

```
on-account-source-conflict = convert
```

in the config file (or environment variable). With this setting,
accounts with same name are treated identical, independet where they
came from. So you can login either locally **or** via the configured
openid provider. Note that this also allows users to set a local
password by themselves (which may not adhere to the password rules you
can potentially define at an openid provider).
