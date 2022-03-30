+++
title = "Database"
insert_anchor_links = "right"
description = "Details about configuring the database."
weight = 20
template = "docs.html"
+++


# Database

The database holds by default all the data and must be configured
exactly the same on all nodes.

The following are supported DBs:

- PostgreSQL (recommended)
- MariaDB
- H2

This has to be specified for the rest server and joex. By default, a
H2 database in the current `/tmp` directory is configured.

## Options

The config looks like this (both components):

``` bash
docspell.joex.jdbc {
  url = ...
  user = ...
  password = ...
}

docspell.server.backend.jdbc {
  url = ...
  user = ...
  password = ...
}
```

The `url` is the connection to the database. It must start with
`jdbc`, followed by name of the database. The rest is specific to the
database used: it is either a path to a file for H2 or a host/database
url for MariaDB and PostgreSQL.

When using H2, the user and password can be chosen freely on first
start, but must stay the same on subsequent starts. Usually, the user
is `sa` and the password is left empty. Additionally, the url must
include these options:

```
;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE
```

## Examples

PostgreSQL:
```
url = "jdbc:postgresql://localhost:5432/docspelldb"
```

MariaDB:
```
url = "jdbc:mariadb://localhost:3306/docspelldb"
```

H2
```
url = "jdbc:h2:///path/to/a/file.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"
```
