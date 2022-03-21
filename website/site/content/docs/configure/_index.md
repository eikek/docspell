+++
title = "Configuration"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 40
template = "docs.html"
+++

# Configuration

Docspell's executables (restserver and joex) can take one argument – a
configuration file. If that is not given, the defaults are used,
overriden by environment variables. A config file overrides default
values, so only values that differ from the defaults are necessary.
The complete default options and their documentation is at the end of
this page.

Besides the config file, another way is to provide individual settings
via key-value pairs to the executable by the `-D` option. For example
to override only `base-url` you could add the argument
`-Ddocspell.server.base-url=…` to the command. Multiple options are
possible. For more than few values this is very tedious, obviously, so
the recommended way is to maintain a config file. If these options
*and* a file is provded, then any setting given via the `-D…` option
overrides the same setting from the config file.

At last, it is possible to configure docspell via environment
variables if there is no config file supplied (if a config file *is*
supplied, it is always preferred). Note that this approach is limited,
as arrays are not supported. A list of environment variables can be
found at the [end of this page](#environment-variables). The
environment variable name follows the corresponding config key - where
dots are replaced by underscores and dashes are replaced by two
underscores. For example, the config key `docspell.server.app-name`
can be defined as env variable `DOCSPELL_SERVER_APP__NAME`.

It is also possible to specify environment variables inside a config
file (to get a mix of both) - please see the [documentation of the
config library](https://github.com/lightbend/config#standard-behavior)
for more on this.

# File Format

The format of the configuration files can be
[HOCON](https://github.com/lightbend/config/blob/master/HOCON.md#hocon-human-optimized-config-object-notation),
JSON or what this [config
library](https://github.com/lightbend/config) understands. The default
values below are in HOCON format, which is recommended, since it
allows comments and has some [advanced
features](https://github.com/lightbend/config#features-of-hocon).
Please also see their documentation for more details.

A short description (please check the links for better understanding):
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

Strings that contain "not-so-common" characters should be enclosed in
quotes. It is possible to define values at the top of the file and
reuse them on different locations via the `${full.path.to.key}`
syntax. When using these variables, they *must not* be enclosed in
quotes.


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


## Full-Text Search

Fulltext search is optional and provided by external systems. There
are currently [Apache SOLR](https://solr.apache.org) and [PostgreSQL's
text search](https://www.postgresql.org/docs/14/textsearch.html)
available.

You can enable and configure the fulltext search backends as described
below and then choose the wanted backend:

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

### SOLR

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
re-created. This is sometimes necessary, for example if you upgrade
SOLR or delete the core to provide a new one (see
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

### PostgreSQL

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
docspell.server.baseurl = "https://docspell.example.com"
docspell.joex.baseurl = "http://192.168.101.10"
```


## App-id

The `app-id` is the identifier of the corresponding instance. It *must
be unique* for all instances. By default the REST server uses `rest1`
and joex `joex1`. It is recommended to overwrite this setting to have
an explicit and stable identifier should multiple instances are
intended.

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

The `session-valid` determines how long a token is valid. This can be
just some minutes, the web application obtains new ones
periodically. So a rather short time is recommended.

## OpenID Connect / OAuth2

You can integrate Docspell into your SSO solution via [OpenID
Connect](https://openid.net/connect/) (OIDC). This requires to set up
an OpenID Provider (OP) somewhere and to configure Docspell
accordingly to act as the relying party.

You can define multiple OPs to use. For some examples, please see the
default configuration file [below](#rest-server).

The configuration of a provider highly depends on how it is setup.
Here is an example for a setup using
[keycloak](https://www.keycloak.org):

``` conf
provider = {
  provider-id = "keycloak",
  client-id = "docspell",
  client-secret = "example-secret-439e-bf06-911e4cdd56a6",
  scope = "profile", # scope is required for OIDC
  authorize-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/auth",
  token-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/token",
  #User URL is not used when signature key is set.
  #user-url = "http://localhost:8080/auth/realms/home/protocol/openid-connect/userinfo",
  sign-key = "b64:MII…ZYL09vAwLn8EAcSkCAwEAAQ==",
  sig-algo = "RS512"
}
```

The `provider-id` is some identifier that is used in the URL to
distinguish between possibly multiple providers. The `client-id` and
`client-secret` define the two parameters required for a "confidential
client". The different URLs are best explained at the [keycloak
docs](https://www.keycloak.org/docs/latest/server_admin/).
They are available for all OPs in some way. The `user-url` is not
required, if the access token is already containing the necessary
data. If not, then docspell performs another request to the
`user-url`, which must be the user-info endpoint, to obtain the
required user data.

If the data is taken from the token directly and not via a request to
the user-info endpoint, then the token must be validated using the
given `sign-key` and `sig-algo`. These two values are then required to
specify! However, if the user-info endpoint should be used, then leave
the `sign-key` empty and specify the correct url in `user-url`. When
specifying the `sign-key` use a prefix of `b64:` if it is Base64
encoded or `hex:` if it is hex encoded. Otherwise the unicode bytes
are used, which is most probably not wanted for this setting.

Once the user is authenticated, docspell tries to setup an account and
does some checks. For this it must get to the username and collective
name somehow. How it does this, can be specified by the `user-key` and
`collective-key` settings:

``` conf
# The collective of the user is given in the access token as
# property `docspell_collective`.
collective-key = "lookup:docspell_collective",
# The username to use for the docspell account
user-key = "preferred_username"
```

The `user-key` is some string that is used to search the JSON response
from the OP for an object with that key. The search happens
recursively, so the field can be in a nested object. The found value
is used as the user name. Keycloak transmits the `preferred_username`
when asking for the `profile` scope. This can be used as the user
name.

The collective name can be obtained by different ways. For example,
you can instruct your OP (like keycloak) to provide a collective name
in the token and/or user-info responses. If you do this, then use the
`lookup:` prefix as in the example above. This instructs docspell to
search for a value the same way as the `user-key`. You can also set a
fixed collective, using `fixed:` prefix; in this case all users are in
the same collective! A third option is to prefix it with `account:` -
then the value that is looked up is interpreted as the full account
name, like `collective/user` and the `user-key` setting is ignored. If
you want to put each user in its own collective, you can just use the
same value as in `user-key`, only prefixed with `lookup:`. In the
example it would be `lookup:preferred_username`.

If you find that these methods do not suffice for your case, please
open an issue.


## File Backends

Docspell allows to choose from different storage backends for binary
files. You can choose between:

1. *Database (the recommended default)*

   The database can be used to store the files as well. It is the
   default. It doesn't require any other configuration and works well
   with multiple instances of restservers and joex nodes.
2. *S3*

   The S3 backend allows to store files in an S3 compatible storage.
   It was tested with MinIO, which is possible to self host.

3. *Filesystem*

   The filesystem can also be used directly, by specifying a
   directory. Be aware that _all_ nodes must have read and write
   access into this directory! When running multiple nodes over a
   network, consider using one of the above instead. Docspell uses a
   fixed structure for storing the files below the given directory, it
   cannot be configured.

When using S3 or filesystem, remember to backup the database *and* the
files!

Note that Docspell not only stores the file that are uploaded, but
also some other files for internal use.

### Configuring

{% warningbubble(title="Note") %}

Each node must have the same config for its file backend! When using
the filesystem, make sure all processes can access the directory with
read and write permissions.

{% end %}

The file storage backend can be configured inside the `files` section
(see the default configs below):

```conf
files {
  …
  default-store = "database"

  stores = {
    database =
      { enabled = true
        type = "default-database"
      }

    filesystem =
      { enabled = false
        type = "file-system"
        directory = "/some/directory"
      }

    minio =
     { enabled = false
       type = "s3"
       endpoint = "http://localhost:9000"
       access-key = "username"
       secret-key = "password"
       bucket = "docspell"
     }
  }
}
```

The `stores` object defines a set of stores and the `default-store`
selects the one that should be used. All disabled store configurations
are removed from the list. Thus the `default-store` must be enabled.
Other enabled stores can be used as the target when copying files (see
below).

A store configuration requires a `enabled` and `type` property.
Depending on the `type` property, other properties are required, they
are presented above. The available storage types are
`default-database`, `file-system` and `s3`.

If you use the docker setup, you can find the corresponding
environment variables to the above config snippet
[below](#environment-variables).

### Change Backends

It is possible to change backends with a bit of manual effort. When
doing this, please make sure that the application is not used. It is
important that no file is uploaded during the following steps.

The [cli](@/docs/tools/cli.md) will be used, please set it up first
and you need to enable the [admin endpoint](#admin-endpoint). Config
changes mentioned here must be applied to all nodes - joex and
restserver!

1. In the config, enable a second file backend (besides the default)
   you want to change to and start docspell as normal. Don't change
   `default-store` yet.
2. Run the file integrity check in order to see whether all files are
   ok as they are in the current store. This can be done using the
   [cli](@/docs/tools/cli.md) by running:

   ```bash
   dsc admin file-integrity-check
   ```
3. Run the copy files admin command which will copy all files from the
   current `default-store` to all other enabled stores.

   ```bash
   dsc admin clone-file-repository
   ```

   And wait until it's done :-). You can see the progress in the jobs
   page when logged in as `docspell-system` or just look at the logs.
4. In the config, change the `default-store` to the one you just
   copied all the files to and restart docspell.
5. Login and do some smoke tests. Then run the file integrity check
   again:

   ```bash
   dsc admin file-integrity-check
   ```

If all is fine, then you are done and are now using the new file
backend. If the second integrity check fails, please open an issue.
You need then to revert the config change of step 4 to use the
previous `default-store` again.

If you want to delete the files from the database, you can do so by
running the following SQL against the database:

```sql
DELETE FROM filechunk
```

You can copy them back into the database using the steps above.


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
models for procesing documents of languaes German, English, French and
Spanish. These require some amount of memory (see below).

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

<table class="striped-basic">
<thead>
  <tr>
     <th>nlp.mode</th>
     <th>English</th>
     <th>German</th>
     <th>French</th>
 </tr>
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


# JVM Options

The start scripts support some options to configure the JVM. One often
used setting is the maximum heap size of the JVM. By default, java
determines it based on properties of the current machine. You can
specify it by given java startup options to the command:

```
$ ./docspell-restserver*/bin/docspell-restserver -J-Xmx1G -- /path/to/server-config.conf
```

This would limit the maximum heap to 1GB. The double slash separates
internal options and the arguments to the program. Another frequently
used option is to change the default temp directory. Usually it is
`/tmp`, but it may be desired to have a dedicated temp directory,
which can be configured:

```
$ ./docspell-restserver*/bin/docspell-restserver -J-Xmx1G -Djava.io.tmpdir=/path/to/othertemp -- /path/to/server-config.conf
```

The command:

```
$ ./docspell-restserver*/bin/docspell-restserver -h
```

gives an overview of supported options.

It is recommended to run joex with the G1GC enabled. If you use java8,
you need to add an option to use G1GC (`-XX:+UseG1GC`), for java11
this is not necessary (but doesn't hurt either). This could look like
this:

```
./docspell-joex-{{version()}}/bin/docspell-joex -J-Xmx1596M -J-XX:+UseG1GC -- /path/to/joex.conf
```

Using these options you can define how much memory the JVM process is
able to use. This might be necessary to adopt depending on the usage
scenario and configured text analysis features.

Please have a look at the corresponding [section](@/docs/configure/_index.md#memory-usage).



# Logging

By default, docspell logs to stdout. This works well, when managed by
systemd or other inits. Logging can be configured in the configuration
file or via environment variables. There are only two settings:

- `minimum-level` specifies the log level to control the verbosity.
  Levels are ordered from: *Trace*, *Debug*, *Info*, *Warn* and
  *Error*
- `format` this defines how the logs are formatted. There are two
  formats for humans: *Plain* and *Fancy*. And two more suited for
  machine consumption: *Json* and *Logfmt*. The *Json* format contains
  all details, while the others may omit some for readability

These settings are the same for joex and the restserver component.

# Default Config
## Rest Server

{{ incl_conf(path="templates/shortcodes/server.conf") }}


## Joex


{{ incl_conf(path="templates/shortcodes/joex.conf") }}

## Environment Variables

Environment variables can be used when there is no config file
supplied. The listing below shows all possible variables and their
default values.

{{ incl_conf(path="templates/shortcodes/config.env.txt") }}
