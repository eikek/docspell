+++
title = "Base URL"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 90
template = "docs.html"
+++

## Baseurl

The base url is an important setting that defines the http URL where
the corresponding component can be reached. It applies to both
components. For a joex component, the url must be resolvable from a
REST server component. The REST server also uses this url to create
absolute urls and to configure the authenication cookie.

By default it is build using the information from the `bind` setting,
which is `http://localhost:7880`.

If the default is not changed, docspell will use the request to
determine the base-url. It first inspects the `X-Forwarded-For` header
that is often used with reverse proxies. If that is not present, the
`Host` header of the request is used. However, if the `base-url`
setting is changed, then only this setting is used.

```
docspell.server.base-url = ...
docspell.joex.base-url = ...
```

If you are unsure, leave it at its default.

### Examples

```
docspell.server.base-url = "https://docspell.example.com"
docspell.joex.base-url = "http://192.168.101.10"
```
