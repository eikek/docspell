+++
title = "Configuration"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 40
[extra]
mktoc = true
+++

Docspell's executable can take one argument – a configuration file. If
that is not given, the defaults are used. The config file overrides
default values, so only values that differ from the defaults are
necessary.

This applies to the restserver and the joex as well.

# Important Config Options

The configuration of both components uses separate namespaces. The
configuration for the REST server is below `docspell.server`, while
the one for joex is below `docspell.joex`.

You can therefore use two separate config files or one single file
containing both namespaces.

## JDBC

This configures the connection to the database. This has to be
specified for the rest server and joex. By default, a H2 database in
the current `/tmp` directory is configured.

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

### Examples

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

## Admin Endpoint

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


## Full-Text Search: SOLR

[Apache SOLR](https://lucene.apache.org/solr) is used to provide the
full-text search. Both docspell components must provide the same
connection setup. This is defined in the `full-text-search.solr`
subsection:

``` bash
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

The `full-text-search.solr` options are the same for joex and the
restserver.

There is an [admin route](@/docs/api/intro.md#admin) that allows to
re-create the entire index (for all collectives). This is possible via
a call:

``` bash
$ curl -XPOST -H "Docspell-Admin-Secret: test123" http://localhost:7880/api/v1/admin/fts/reIndexAll
```

Here the `test123` is the key defined with `admin-endpoint.secret`. If
it is empty (the default), this call is disabled (all admin routes).
Otherwise, the POST request will submit a system task that is executed
by a joex instance eventually.

Using this endpoint, the index will be re-created. This is sometimes
necessary, for example if you upgrade SOLR or delete the core to
provide a new one (see
[here](https://lucene.apache.org/solr/guide/8_4/reindexing.html) for
details). Note that a collective can also re-index their data using a
similiar endpoint; but this is only deleting their data and doesn't do
a full re-index.

The solr index doesn't contain any new information, it can be
regenerated any time using the above REST call. Thus it doesn't need
to be backed up.

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

## Baseurl

The base url is an important setting that defines the http URL where
the corresponding component can be reached. It applies to both
components. For a joex component, the url must be resolvable from a
REST server component. The REST server also uses this url to create
absolute urls and to configure the authenication cookie.

By default it is build using the information from the `bind` setting,
which is `http://localhost:7880`.

If the default is not changed, docspell will use the login request to
determine the base-url. It first inspects the `X-Forwarded-For` header
that is often used with reverse proxies. If that is not present, the
`Host` header of the request is used. However, if the `base-url`
setting is changed, then only this setting is used.

```
docspell.server.base-url = ...
docspell.joex.base-url = ...
```

### Examples

```
docspell.server.baseurl = "https://docspell.example.com"
docspell.joex.baseurl = "http://192.168.101.10"
```


## App-id

The `app-id` is the identifier of the corresponding instance. It *must
be unique* for all instances. By default the REST server uses `rest1`
and joex `joex1`. It is recommended to overwrite this setting to have
an explicit and stable identifier.

``` bash
docspell.server.app-id = "rest1"
docspell.joex.app-id = "joex1"
```

## Registration Options

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

## Authentication

Authentication works in two ways:

- with an account-name / password pair
- with an authentication token

The initial authentication must occur with an accountname/password
pair. This will generate an authentication token which is valid for a
some time. Subsequent calls to secured routes can use this token. The
token can be given as a normal http header or via a cookie header.

These settings apply only to the REST server.

``` bash
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


## File Processing

Files are being processed by the joex component. So all the respective
configuration is in this config only.

File processing involves several stages, detailed information can be
found [here](@/docs/joex/file-processing.md#text-analysis) and in the
corresponding sections in [joex default config](#joex).

Configuration allows to define the external tools and set some
limitations to control memory usage. The sections are:

- `docspell.joex.extraction`
- `docspell.joex.text-analysis`
- `docspell.joex.convert`

Options to external commands can use variables that are replaced by
values at runtime. Variables are enclosed in double braces `{{…}}`.
Please see the default configuration for what variables exist per
command.

### Classification

In `text-analysis.classification` you can define how many documents at
most should be used for learning. The default settings should work
well for most cases. However, it always depends on the amount of data
and the machine that runs joex. For example, by default the documents
to learn from are limited to 600 (`classification.item-count`) and
every text is cut after 5000 characters (`text-analysis.max-length`).
This is fine if *most* of your documents are small and only a few are
near 5000 characters). But if *all* your documents are very large, you
probably need to either assign more heap memory or go down with the
limits.

Classification can be disabled, too, for when it's not needed.

### NLP

This setting defines which NLP mode to use. It defaults to `full`,
which requires more memory for certain languages (with the advantage
of better results). Other values are `basic`, `regexonly` and
`disabled`. The modes `full` and `basic` use pre-defined lanugage
models for procesing documents of languaes German, English and French.
These require some amount of memory (see below).

The mode `basic` is like the "light" variant to `full`. It doesn't use
all NLP features, which makes memory consumption much lower, but comes
with the compromise of less accurate results.

The mode `regexonly` doesn't use pre-defined lanuage models, even if
available. It checks your address book against a document to find
metadata. That means, it is language independent. Also, when using
`full` or `basic` with lanugages where no pre-defined models exist, it
will degrade to `regexonly` for these.

The mode `disabled` skips NLP processing completely. This has least
impact in memory consumption, obviously, but then only the classifier
is used to find metadata (unless it is disabled, too).

You might want to try different modes and see what combination suits
best your usage pattern and machine running joex. If a powerful
machine is used, simply leave the defaults. When running on an
raspberry pi, for example, you might need to adjust things.

### Memory Usage

The memory requirements for the joex component depends on the document
language and the enabled features for text-analysis. The `nlp.mode`
setting has significant impact, especially when your documents are in
German. Here are some rough numbers on jvm heap usage (the same file
was used for all tries):

<table class="table is-hoverable is-striped">
<thead>
  <tr><th>nlp.mode</th><th>English</th><th>German</th><th>French</th></tr>
</thead>
<tfoot>
</tfoot>
<tbody>
  <tr><td>full</td><td>420M</td><td>950M</td><td>490M</td></tr>
  <tr><td>basic</td><td>170M</td><td>380M</td><td>390M</td></tr>
</tbody>
</table>

Note that these are only rough numbers and they show the maximum used
heap memory while processing a file.

When using `mode=full`, a heap setting of at least `-Xmx1400M` is
recommended. For `mode=basic` a heap setting of at least `-Xmx500M` is
recommended.

Other languages can't use these two modes, and so don't require this
amount of memory (but don't have as good results). Then you can go
with less heap. For these languages, the nlp mode is the same as
`regexonly`.

Training the classifier is also memory intensive, which solely depends
on the size and number of documents that are being trained. However,
training the classifier is done periodically and can happen maybe
every two weeks. When classifying new documents, memory requirements
are lower, since the model already exists.

More details about these modes can be found
[here](@/docs/joex/file-processing.md#text-analysis).


The restserver component is very lightweight, here you can use
defaults.


# File Format

The format of the configuration files can be
[HOCON](https://github.com/lightbend/config/blob/master/HOCON.md#hocon-human-optimized-config-object-notation),
JSON or whatever the used [config
library](https://github.com/lightbend/config) understands. The default
values below are in HOCON format, which is recommended, since it
allows comments and has some [advanced
features](https://github.com/lightbend/config#features-of-hocon).
Please refer to their documentation for more on this.

A short description (please see the links for better understanding):
The config consists of key-value pairs and can be written in a
JSON-like format (called HOCON). Keys are organized in trees, and a
key defines a full path into the tree. There are two ways:

```
a.b.c.d=15
```

or

```
a {
  b {
    c {
      d = 15
    }
  }
}
```

Both are exactly the same and these forms are both used at the same
time. Usually the braces approach is used to group some more settings,
for better readability.


# Default Config
## Rest Server

{{ incl_conf(path="templates/shortcodes/server.conf") }}


## Joex


{{ incl_conf(path="templates/shortcodes/joex.conf") }}


# Logging

By default, docspell logs to stdout. This works well, when managed by
systemd or other inits. Logging is done by
[logback](https://logback.qos.ch/). Please refer to its documentation
for how to configure logging.

If you created your logback config file, it can be added as argument
to the executable using this syntax:

``` bash
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
