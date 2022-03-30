+++
title = "Bind"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 12
template = "docs.html"
+++

## Bind

The host and port the http server binds to. This applies to both
components. The joex component also exposes a small REST api to
inspect its state and notify the scheduler.

``` bash
docspell.server.bind {
  address = localhost
  port = 7880
}
docspell.joex.bind {
  address = localhost
  port = 7878
}
```

By default, it binds to `localhost` and some predefined port. This
must be changed, if components are on different machines.
