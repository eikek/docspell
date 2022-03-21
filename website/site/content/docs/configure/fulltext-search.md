+++
title = "Full-Text Search"
insert_anchor_links = "right"
description = "Details about configuring the fulltext search."
weight = 50
template = "docs.html"
+++


# Full-Text Search

Fulltext search is optional and provided by external systems. There
are currently [Apache SOLR](https://solr.apache.org) and [PostgreSQL's
text search](https://www.postgresql.org/docs/14/textsearch.html)
available.

You can enable and configure the fulltext search backends as described
below and then choose the backend:

```conf
full-text-search {
  enabled = true
  # Which backend to use, either solr or postgresql
  backend = "solr"
  …
}
```

All docspell components must provide the same fulltext search
configuration.


## SOLR

[Apache SOLR](https://solr.apache.org) can be used to provide the
full-text search. This is defined in the `full-text-search.solr`
subsection:

``` bash
...
  full-text-search {
    ...
    solr = {
      url = "http://localhost:8983/solr/docspell"
    }
  }
```

The default configuration at the end of this page contains more
information about each setting.

The `solr.url` is the mandatory setting that you need to change to
point to your SOLR instance. Then you need to set the `enabled` flag
to `true`.

When installing docspell manually, just install solr and create a core
as described in the [solr
documentation](https://solr.apache.org/guide/8_4/installing-solr.html).
That will provide you with the connection url (the last part is the
core name). If Docspell detects an empty core it will run a schema
setup on start automatically.

The `full-text-search.solr` options are the same for joex and the
restserver.

Sometimes it is necessary to re-create the entire index, for example
if you upgrade SOLR or delete the core to provide a new one (see
[here](https://solr.apache.org/guide/8_4/reindexing.html) for
details). Another way is to restart docspell (while clearing the
index). If docspell detects an empty index at startup, it will submit
a task to build the index automatically.

Note that a collective can also re-index their data using a similiar
endpoint; but this is only deleting their data and doesn't do a full
re-index.

The solr index doesn't contain any new information, it can be
regenerated any time using the above REST call. Thus it doesn't need
to be backed up.


## PostgreSQL

PostgreSQL provides many additional features, one of them is [text
search](https://www.postgresql.org/docs/14/textsearch.html). Docspell
can utilize this to provide the fulltext search feature. This is
especially useful, if PostgreSQL is used as the primary database for
docspell.

You can choose to use the same database or separate connection. The
fulltext search will create a single table `ftspsql_search` that holds
all necessary data. When doing backups, you can exclude this table as
it can be recreated from the primary data any time.

The configuration is placed inside `full-text-search`:

```conf
full-text-search {
  …
  postgresql = {
    use-default-connection = false

    jdbc {
      url = "jdbc:postgresql://server:5432/db"
      user = "pguser"
      password = ""
    }

    pg-config = {
    }
    pg-query-parser = "websearch_to_tsquery"
    pg-rank-normalization = [ 4 ]
  }
}
```

The flag `use-default-connection` can be set to `true` if you use
PostgreSQL as the primary db to have it also used for the fulltext
search. If set to `false`, the subsequent `jdbc` block defines the
connection to the postgres database to use.

It follows some settings to tune PostgreSQL's text search feature.
Please visit [their
documentation](https://www.postgresql.org/docs/14/textsearch.html) for
all the details.

- `pg-config`: this is an optional mapping from document languages as
  used in Docspell to a PostgreSQL text search configuration. Not all
  languages are equally well supported out of the box. You can create
  your own text search config in PostgreSQL and then define it in this
  map for your language. For example:

  ```conf
  pg-config = {
    english = "my-english"
    german = "my-german"
  }
  ```

  By default, the predefined configs are used for some lanugages and
  otherwise fallback to `simple`.

  *If you change this setting, you must re-index everything.*
- `pg-query-parser`: the parser applied to the fulltext query. By
  default it is `websearch_to_tsquery`. (relevant [doc
  link](https://www.postgresql.org/docs/14/textsearch-controls.html#TEXTSEARCH-PARSING-QUERIES))
- `pg-rank-normalization`: this is used to tweak rank calculation that
  affects the order of the elements returned from a query. It is an
  array of numbers out of `1`, `2`, `4`, `8`, `16` or `32`. (relevant
  [doc
  link](https://www.postgresql.org/docs/14/textsearch-controls.html#TEXTSEARCH-RANKING))


# Re-create the index

There is an [admin route](@/docs/api/intro.md#admin) that allows to
re-create the entire index (for all collectives). This is possible via
a call:

``` bash
$ curl -XPOST -H "Docspell-Admin-Secret: test123" http://localhost:7880/api/v1/admin/fts/reIndexAll
```

or use the [cli](@/docs/tools/cli.md):

```bash
dsc admin -a test123 recreate-index
```

Here the `test123` is the key defined with `admin-endpoint.secret`. If
it is empty (the default), this call is disabled (all admin routes).
Otherwise, the POST request will submit a system task that is executed
by a joex instance eventually.

Using this endpoint, the entire index (including the schema) will be
re-created.
