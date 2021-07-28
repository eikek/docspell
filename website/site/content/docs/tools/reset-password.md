+++
title = "Reset Password (⊗)"
description = "Resets a user password."
weight = 120
+++

{% infobubble(mode="info", title="⚠ Please note") %}
This script is now obsolete, you can use the [**CLI tool**](../cli/) instead.

Use the `reset-password` admin command, e.g. `dsc admin reset-password
--account "smith/john"`, where `smith` is the collective id and `john`
the username.
{% end %}


This script can be used to reset a user password. This can be done by
admins, who know the `admin-endpoint.secret` value in the
[configuration](@/docs/configure/_index.md#admin-endpoint) file.

The script is in `/tools/reset-password/reset-password.sh` and it is
only a wrapper around the admin endpoint `/admin/user/resetPassword`.

## Usage

It's very simple:

``` bash
reset-password.sh <base-url> <admin-secret> <account>
```

Three arguments are required to specify the docspell base url, the
admin secret and the account you want to reset the password.

After the password has been reset, the user can login using it and
change it again in the webapp.


## Example

``` json
❯ ./tools/reset-password/reset-password.sh http://localhost:7880 123 eike
{
  "success": true,
  "newPassword": "HjtpG9BFo9y",
  "message": "Password updated"
}
```
