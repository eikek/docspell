+++
title = "Default Configuration"
insert_anchor_links = "right"
description = "Shows the default settings."
weight = 100
template = "docs.html"
+++

## Default Configuration

Below is the default config file for the restserver and joex. If you
create a config file, you only need to include settings that differ
from the default config.

## Rest Server

{{ incl_conf(path="templates/shortcodes/server.conf") }}


## Joex

{{ incl_conf(path="templates/shortcodes/joex.conf") }}


## Environment Variables

Environment variables can be used when there is no config file
supplied.

There is one caveat: The configuration files above reuse values by
referencing them. This applies for example to the `app-id` - it is
used at other places, where the config file simply references it via
its full path. For example for the scheduler name, the default value
is `${docspell.joex.app-id}`. This way the value of `scheduler.name`
is always the same as `app-id`. But this doesn't work with env
variables! Here you'd need to update each such value.

For example, when creating multiple joex', they must have different
`app-id`s and with this, these values need to be set as well:

```
DOCSPELL_JOEX_APP__ID=joex2
DOCSPELL_JOEX_PERIODIC__SCHEDULER_NAME=joex2
DOCSPELL_JOEX_SCHEDULER_NAME=joex2
```

The listing below shows all possible variables and their default
values.

{{ incl_conf(path="templates/shortcodes/config.env.txt") }}
