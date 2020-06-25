---
layout: docs
title: Configuring
permalink: doc/configure
---

# {{ page.title }}

Docspell's executable can take one argument – a configuration file. If
that is not given, the defaults are used. The config file overrides
default values, so only values that differ from the defaults are
necessary.

This applies to the restserver and the joex as well.

## Important Config Options

The configuration of both components uses separate namespaces. The
configuration for the REST server is below `docspell.server`, while
the one for joex is below `docspell.joex`.

### JDBC

This configures the connection to the database. This has to be
specified for the rest server and joex. By default, a H2 database in
the current `/tmp` directory is configured.

The config looks like this (both components):

```
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

#### Examples

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


### Full-Text Search: SOLR

[Apache SOLR](https://lucene.apache.org/solr) is used to provide the
full-text search. Both docspell components must provide the same
connection setup. This is defined in the `full-text-search.solr`
subsection:

```
...
  full-text-search {
    enabled = true
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
documentation](https://lucene.apache.org/solr/guide/8_4/installing-solr.html).
That will provide you with the connection url (the last part is the
core name).

While the `full-text-search.solr` options are the same for joex and
the restserver, there are some settings that differ. The restserver
has this additional setting, that may be of interest:

```
full-text-search {
  recreate-key = "test123"
}
```

This key is required if you want docspell to drop and re-create the
entire index. This is possible via a REST call:

``` shell
$ curl -XPOST http://localhost:7880/api/v1/open/fts/reIndexAll/test123
```

Here the `test123` is the key defined with `recreate-key`. If it is
empty (the default), this REST call is disabled. Otherwise, the POST
request will submit a system task that is executed by a joex instance
eventually.

Using this endpoint, the index will be re-created. This is sometimes
necessary, for example if you upgrade SOLR or delete the core to
provide a new one (see
[here](https://lucene.apache.org/solr/guide/8_4/reindexing.html) for
details). Note that a collective can also re-index their data using a
similiar endpoint; but this is only deleting their data and doesn't do
a full re-index.

### Bind

The host and port the http server binds to. This applies to both
components. The joex component also exposes a small REST api to
inspect its state and notify the scheduler.

```
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

### baseurl

The base url is an important setting that defines the http URL where
the corresponding component can be reached. It applies to both
components. For a joex component, the url must be resolvable from a
REST server component. The REST server also uses this url to create
absolute urls and to configure the authenication cookie.

By default it is build using the information from the `bind` setting.


```
docspell.server.baseurl = ...
docspell.joex.baseurl = ...
```

#### Examples

```
docspell.server.baseurl = "https://docspell.example.com"
docspell.joex.baseurl = "http://192.168.101.10"
```


### app-id

The `app-id` is the identifier of the corresponding instance. It *must
be unique* for all instances. By default the REST server uses `rest1`
and joex `joex1`. It is recommended to overwrite this setting to have
an explicit and stable identifier.

```
docspell.server.app-id = "rest1"
docspell.joex.app-id = "joex1"
```

### registration options

This defines if and how new users can create accounts. There are 3
options:

- *closed* no new user can sign up
- *open* new users can sign up
- *invite* new users can sign up but require an invitation key

This applies only to the REST sevrer component.

```
docspell.server.signup {
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

```
curl -X POST -d '{"password":"blabla"}' "http://localhost:7880/api/v1/open/signup/newinvite"
```

### Authentication

Authentication works in two ways:

- with an account-name / password pair
- with an authentication token

The initial authentication must occur with an accountname/password
pair. This will generate an authentication token which is valid for a
some time. Subsequent calls to secured routes can use this token. The
token can be given as a normal http header or via a cookie header.

These settings apply only to the REST server.

```
docspell.server.auth {
  server-secret = "hex:caffee" # or "b64:Y2FmZmVlCg=="
  session-valid = "5 minutes"
}
```

The `server-secret` is used to sign the token. If multiple REST
servers are deployed, all must share the same server secret. Otherwise
tokens from one instance are not valid on another instance. The secret
can be given as Base64 encoded string or in hex form. Use the prefix
`hex:` and `b64:`, respectively. If no prefix is given, the UTF8 bytes
of the string are used.

The `session-valid` deterimens how long a token is valid. This can be
just some minutes, the web application obtains new ones
periodically. So a short time is recommended.


## File Format

The format of the configuration files can be
[HOCON](https://github.com/lightbend/config/blob/master/HOCON.md#hocon-human-optimized-config-object-notation),
JSON or whatever the used [config
library](https://github.com/lightbend/config) understands. The default
values below are in HOCON format, which is recommended, since it
allows comments and has some [advanced
features](https://github.com/lightbend/config/blob/master/README.md#features-of-hocon). Please
refer to their documentation for more on this.

Here are the default configurations.


## Default Config

### Rest Server

```
{% include server.conf %}
```

### Joex

```
{% include joex.conf %}
```

## Logging

By default, docspell logs to stdout. This works well, when managed by
systemd or other inits. Logging is done by
[logback](https://logback.qos.ch/). Please refer to its documentation
for how to configure logging.

If you created your logback config file, it can be added as argument
to the executable using this syntax:

```
/path/to/docspell -Dlogback.configurationFile=/path/to/your/logging-config-file
```

To get started, the default config looks like this:

``` xml
<configuration>
  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <withJansi>true</withJansi>

    <encoder>
      <pattern>[%thread] %highlight(%-5level) %cyan(%logger{15}) - %msg %n</pattern>
    </encoder>
  </appender>

  <logger name="docspell" level="debug" />
  <root level="INFO">
    <appender-ref ref="STDOUT" />
  </root>
</configuration>
```

The `<root level="INFO">` means, that only log statements with level
"INFO" will be printed. But the `<logger name="docspell"
level="debug">` above says, that for loggers with name "docspell"
statements with level "DEBUG" will be printed, too.
