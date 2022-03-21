+++
title = "Registration"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 80
template = "docs.html"
+++

# Registration Options

This defines if and how new users can create accounts. There are 3
options:

- *closed* no new user can sign up
- *open* new users can sign up
- *invite* new users can sign up but require an invitation key

This applies only to the REST sevrer component.

``` bash
docspell.server.backend.signup {
  mode = "open"

  # If mode == 'invite', a password must be provided to generate
  # invitation keys. It must not be empty.
  new-invite-password = ""

  # If mode == 'invite', this is the period an invitation token is
  # considered valid.
  invite-time = "3 days"
}
```

The mode `invite` is intended to open the application only to some
users. The admin can create these invitation keys and distribute them
to the desired people. For this, the `new-invite-password` must be
given. The idea is that only the person who installs docspell knows
this. If it is not set, then invitation won't work. New invitation
keys can be generated from within the web application or via REST
calls (using `curl`, for example).

``` bash
curl -X POST -d '{"password":"blabla"}' "http://localhost:7880/api/v1/open/signup/newinvite"
```
