+++
title = "Admin Endpoint"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 60
template = "docs.html"
+++

# Admin Endpoint

The admin endpoint defines some [routes](@/docs/api/intro.md#admin)
for adminstration tasks. This is disabled by default and can be
enabled by providing a secret:

``` bash
...
  admin-endpoint {
    secret = "123"
  }
```

This secret must be provided to all requests to a `/api/v1/admin/`
endpoint.

The most convenient way to execute admin tasks is to use the
[cli](@/docs/tools/cli.md). You get a list of possible admin commands
via `dsc admin help`.

To see the output of the commands, there are these ways:

1. looking at the joex logs, which gives most details.
2. Use the job-queue page when logged in as `docspell-system`
3. setup a [webhook](@/docs/webapp/notification.md) to be notified
   when a job finishes. This way you get a small message.

All admin tasks (and also some other system tasks) are run under the
account `docspell-system` (collective and user). You need to create
this account and setup the notification hooks in there - not in your
normal account.
