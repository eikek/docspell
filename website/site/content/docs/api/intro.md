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

The routes can be divided into protected and unprotected routes. The
unprotected, or open routes are at `/open/*` while the protected
routes are at `/sec/*`. Open routes don't require authenticated access
and can be used by any user. The protected routes require an
authenticated user.

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
