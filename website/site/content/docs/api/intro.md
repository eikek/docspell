+++
title = "Api Introduction"
description = "Api Basics"
weight = 10
insert_anchor_links = "right"
[extra]
mktoc = true
+++

Docspell is designed as a REST server that uses JSON to exchange
data. The REST api can be used to integrate docspell into your
workflow.

[Docspell REST Api Doc](/openapi/docspell-openapi.html)

The "raw" `openapi.yml` specification file can be found
[here](/openapi/docspell-openapi.yml).

The routes can be divided into protected, unprotected routes and admin
routes. The unprotected, or open routes are at `/open/*` while the
protected routes are at `/sec/*` and admin routes are at `/admin/*`.
Open routes don't require authenticated access and can be used by any
user. The protected routes require an authenticated user. The admin
routes require a special http header with a value from the config
file. They are disabled by default, you need to specify a secret in
order to enable admin routes.

## Authentication

The unprotected route `/open/auth/login` can be used to login with
account name and password. The response contains a token that can be
used for accessing protected routes. The token is only valid for a
restricted time which can be configured (default is 5 minutes).

New tokens can be generated using an existing valid token and the
protected route `/sec/auth/session`. This will return the same
response as above, giving a new token.

This token can be added to requests in two ways: as a cookie header or
a "normal" http header. If a cookie header is used, the cookie name
must be `docspell_auth` and a custom header must be named
`X-Docspell-Auth`.

The admin route (see below) `/admin/user/resetPassword` can be used to
reset a password of a user.

## Admin

There are some endpoints available for adminstration tasks, for
example re-creating the complete fulltext index or resetting a
password. These endpoints are not available to normal users, but to
admins only. Docspell has no special admin users, it simply uses a
secret defined in the configuration file. The person who installs
docspell is the admin and knows this secret (and may share it) and
requests must provide it as a http header `Docspell-Admin-Secret`.

Example: re-create the fulltext index (over all collectives):

``` bash
$ curl -XPOST -H "Docspell-Admin-Secret: test123" http://localhost:7880/api/v1/admin/fts/reIndexAll
```

To enable these endpoints, you must provide a secret in the
[configuration](@/docs/configure/_index.md#admin-endpoint).

## Live Api

Besides the statically generated documentation at this site, the rest
server provides a swagger generated api documenation, that allows
playing around with the api. It requires a running docspell rest
server. If it is deployed at `http://localhost:7880`, then check this
url:

```
http://localhost:7880/api/doc
```

## Examples

These examples use the great command line tool
[curl](https://curl.haxx.se/).

### Login

``` bash
$ curl -X POST -d '{"account": "smith", "password": "test"}' http://localhost:7880/api/v1/open/auth/login
{"collective":"smith"
,"user":"smith"
,"success":true
,"message":"Login successful"
,"token":"1568142350115-ZWlrZS9laWtl-$2a$10$rGZUFDAVNIKh4Tj6u6tlI.-O2euwCvmBT0TlyDmIHR1ZsLQPAI="
,"validMs":300000
}
```

### Get new token

``` bash
$ curl -XPOST -H 'X-Docspell-Auth: 1568142350115-ZWlrZS9laWtl-$2a$10$rGZUFDAVNIKh4Tj6u6tlI.-O2euwCvmBT0TlyDmIHR1ZsLQPAI=' http://localhost:7880/api/v1/sec/auth/session
{"collective":"smith"
,"user":"smith"
,"success":true
,"message":"Login successful"
,"token":"1568142446077-ZWlrZS9laWtl-$2a$10$3B0teJ9rMpsBJPzHfZZPoO-WeA1bkfEONBN8fyzWE8DeaAHtUc="
,"validMs":300000
}
```

### Get some insights

``` bash
$ curl -H 'X-Docspell-Auth: 1568142446077-ZWlrZS9laWtl-$2a$10$3B0teJ9rMpsBJPzHfZZPoO-WeA1bkfEONBN8fyzWE8DeaAHtUc=' http://localhost:7880/api/v1/sec/collective/insights
{"incomingCount":3
,"outgoingCount":1
,"itemSize":207310
,"tagCloud":{"items":[]}
}
```

### Search for items

``` bash
$ curl -i -H 'X-Docspell-Auth: 1615240493…kYtFynj4' \
  'http://localhost:7880/api/v1/sec/item/search?q=tag=todo,invoice%20year:2021'
{
  "groups": [
    {
      "name": "2021-02",
      "items": [
        {
          "id": "41J962DjS7T-sjP9idxJ6o9-hJrmBk34YJN-mQqysHwcFD6",
          "name": "something.txt",
          "state": "confirmed",
          "date": 1613598750202,
          "dueDate": 1617883200000,
          "source": "webapp",
          "direction": "outgoing",
          "corrOrg": {
            "id": "J58tYifCh4X-cze5R8eSJcc-YAFr6qt1VKL-1ZmhRwiTXoH",
            "name": "EasyCare AG"
          },
          "corrPerson": null,
          "concPerson": null,
          "concEquipment": null,
          "folder": {
            "id": "GKwSvYVdvfb-QeAwzzT7pBM-Gbji2hQc2bL-uCyrMCAg3wo",
            "name": "test"
          },
          "attachments": [],
          "tags": [],
          "customfields": [],
          "notes": null,
          "highlighting": []
        }
      ]
    },
    {
      "name": "2021-01",
      "items": [
        {
          "id": "ANqtuDynXWU-PrhzUxzQVmH-PDuJfeJ6dYB-Ut3g1jrcFhw",
          "name": "letter-de.pdf",
          "state": "confirmed",
          "date": 1611144000000,
          "dueDate": null,
          "source": "webapp",
          "direction": "incoming",
          "corrOrg": {
            "id": "J58tYifCh4X-cze5R8eSJcc-YAFr6qt1VKL-1ZmhRwiTXoH",
            "name": "EasyCare AG"
          },
          "corrPerson": null,
          "concPerson": {
            "id": "AA5sV1nH9ve-mDCn4DxDRvu-tWkUquiW4fZ-fVJimW4Vq79",
            "name": "Max Mustermann"
          },
          "concEquipment": null,
          "folder": null,
          "attachments": [],
          "tags": [],
          "customfields": [],
          "notes": null,
          "highlighting": []
        }
      ]
    }
  ]
}
```
