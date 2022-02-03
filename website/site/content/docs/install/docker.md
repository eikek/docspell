+++
title = "Docker"
weight = 20
+++

# Docker Images

The docker images are at
[hub.docker.com](https://hub.docker.com/u/docspell). The `latest` tag
always points to the latest *release*. The releases are also tagged
with their respective version number. Additionally, there are images
tagged with `nightly` which are built from the `master` branch.
Therefore the `nightly` packages should be used with care, because
things might break in between. But they are useful for trying out
something.

There are images for all components that are available from the github
release page. The images contain all the necessary
[prerequisites](@/docs/install/prereq.md).

- `docspell/restserver` this images contains the http server
- `docspell/joex` this image contains the job executor and all
  required software (ocrmypdf, unoconv etc) mentioned in
  [prerequisites](@/docs/install/prereq.md).
- `docspell/dsc` this is an image containing a
  [cli](@/docs/tools/cli.md) for docspell that can be used to watch
  directories for new files. It doesn't specify a `CMD` or
  `ENTRYPOINT`, so you must specify the exact command to run. Here, it
  is used to watch a directory for uploading files. This runs the `dsc
  watch` command.

## Examples

These examples use `docker run` to start the restserver and
jobexecutor. Both must be connected to the same database. For this
example, a shared directory is used and the in-process database H2.
For a real setup, using PostgreSQL is recommended.

This requires to change the default config. This example creates a new
config file. Please refer to the [configuration
page](@/docs/configure/_index.md) for more details.

``` bash
$ cat > /tmp/docspell.conf <<-"EOF"
# common settings
db_url = "jdbc:h2:///var/docspell/db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"

# job executor settings
docspell.joex.jdbc.url = ${db_url}
docspell.joex.base-url = "http://10.4.3.2:7878"
docspell.joex.bind.address = "0.0.0.0"

# restserver settings
docspell.server.backend.jdbc.url = ${db_url}
docspell.server.bind.address = "0.0.0.0"
docspell.server.integration-endpoint {
  enabled = true
  http-header {
    enabled = true
    header-value = "test123"
  }
}
EOF
```

This sets the db url to the same value for both components; thus we
can use the same file for both components. It also sets the bind
address to bind the server socket on all interfaces. Another thing to
note is the `base-url` setting for joex. This publishes joex by this
ip, such that the server component can notify the job executor for new
work. The `integration-endpoint` setting is explained later.

After creating a common network, we start the rest server and joex:
```
$ docker network create --subnet 10.4.3.0/24 dsnet
$ docker run -d --name ds-restserver \
    --network dsnet --ip 10.4.3.3 \
    -p 127.0.0.1:7880:7880 \
    -v /tmp/testdb:/var/docspell \
    -v /tmp/docspell.conf:/opt/docspell.conf \
    docspell/restserver:latest /opt/docspell.conf
$ docker run -d --name ds-joex \
    --network dsnet --ip 10.4.3.2 \
    -v /tmp/testdb:/var/docspell \
    -v /tmp/docspell.conf:/opt/docspell.conf \
    docspell/joex:latest /opt/docspell.conf
```

After this `docker ps` should show these two containers. Go to
`http://localhost:7880` and sign up/login and start playing around.
When signing up, use the same name for collective and user and then
login with this name.

For the last part, we use the `docspell/dsc` image to create another
container that watches a directory and pushes files to docspell.

``` bash
$ docker run -d --name ds-consume \
    --network dsnet --ip 10.4.3.4 \
    -v /tmp/inbox:/var/inbox \
    docspell/dsc:latest dsc -v -d http://10.4.3.3:7880 watch -r --delete -i \
      --header "Docspell-Integration:test123" /var/inbox
```

This starts the [dsc](@/docs/tools/cli.md) tool that watches a
directory and uploads arriving files to the docspell server. This
requires the value from the `integration-endpoint` setting to be
allowed to upload files. It also requires you to explicitely enable
this: go to *Collective Profile → Settings* and enable the
*Integration Endpoint*. Then create a subdirectory in `/tmp/inbox`
with the name of the *collective* that you registered and place a file
into the `/tmp/inbox/[collective]` directory. The file is pushed to
docspell and processed shortly after.

To see all available options, run `dsc` with the `--help` option:
``` bash
$ docker run docspell/dsc:latest dsc --help
```

Or just [download the
binary](https://github.com/docspell/dsc/releases/latest), no docker
required.

Note that this is just an example and is only to demonstrate how to
use the docker images. For instance, this setup does not provide
fulltext search. For a more sophisticated docker setup, use
appropriate tools, for example `docker-compose` which is explained
below.

# Docker Compose

There is a [docker-compose](https://docs.docker.com/compose/) setup
available in the `/docker/docker-compose` folder. This setup is
similiar to the example above, but adding fulltext search and a
PostgreSQL database by using just one command. It's only a few steps
to get started.

## Start Docspell
### 1. Get the docker-compose files

There are two options. You can clone the whole repository:

```bash
$ git clone https://github.com/eikek/docspell
```

This downloads all sources. What you actually need is only 3 files. So
if you don't have git or don't want to clone the whole repo, use these
steps instead:

``` bash
$ mkdir -p docspell/docker/docker-compose
$ cd docspell/docker/docker-compose
$ wget https://raw.githubusercontent.com/eikek/docspell/master/docker/docker-compose/docker-compose.yml
```

You can choose any directory instead of
`docspell/docker/docker-compose`, of course. It's only this folder to
make the rest of the guide work for both ways of obtaining the
docker-compose file.

### 2. Run `docker-compose up`

Change into the new `docker-compose` directory, for example:

```bash
$ cd docspell/docker/docker-compose
```

Then run `docker-compose`:

```bash
$ docker-compose up -d
```

If you look at `docker-compose.yml`, there are several environment
variables defined. A few that you should change, i.e. all "secrets":

- `DOCSPELL_SERVER_ADMIN__ENDPOINT_SECRET`
- `DOCSPELL_SERVER_AUTH_SERVER__SECRET`
- `DOCSPELL_SERVER_INTEGRATION__ENDPOINT_HTTP__HEADER_HEADER__VALUE`

Then, the value for
`DOCSPELL_SERVER_INTEGRATION__ENDPOINT_HTTP__HEADER_HEADER__VALUE`
must be duplicated in the consumedir command (both values must match).
It is the header defined for the [integration
endpoint](@/docs/api/upload.md#integration-endpoint). You can use
whatever you like, best something random. Please see the help to the
[dsc tool](@/docs/tools/cli.md) docs for additional info.

Goto `http://localhost:7880`, signup and login. When signing up,
choose the same name for collective and user. Then login with this
name and the password.

(Optional) Create a folder `./docs/<collective-name>` (the name you
chose for the collective at registration) and place files in there for
importing them.

Docspell can be configured via environment variables or a config file.
Please see the [configuration](@/docs/configure/_index.md) for more
details and possible values/variables. You can create a config file
and mount it into the container. Then specify the config file as the
an argument to the command, i.e. add a

``` yml
command:
  - /path/to/config.conf
```

to the service definition (or add it to an existing `command:`
section).

## Override this setup

If you want to change this setup, you can simply use your own compose
file or add a `docker-compose.override.yml` that allows to amend
certain configs. Look [here](https://docs.docker.com/compose/extends/)
to find more about it.

As an example, here is a `docker-compose.override.yml`:

``` yaml
version: '3.7'

services:
  consumedir:
    volumes:
      - importdocs:/opt/docs

volumes:
  docspell-postgres_data:
    driver: local
    driver_opts:
      type: nfs4
      o: addr=192.168.x.y,rw,noatime,rsize=8192,wsize=8192,tcp,timeo=14
      device: ":/mnt/FreeNas/docker_vol1/docspell/postgres_data"

  docspell-solr_data:
    driver: local
    driver_opts:
      type: nfs4
      o: addr=192.168.x.y,rw,noatime,rsize=8192,wsize=8192,tcp,timeo=14
      device: ":/mnt/FreeNas/docker_vol1/docspell/solr_data"

  importdocs:
    driver: local
    driver_opts:
      type: nfs4
      o: addr=192.168.x.y,rw,noatime,rsize=8192,wsize=8192,tcp,timeo=14
      device: ":/mnt/FreeNas/archiv/gescannt/output"
```


## Upgrading

Since [downgrading](@/docs/install/downgrading.md) is not supported,
it is recommended to backup your database before upgrading. Should
something not work as expected, restore the database backup and go
back to the previous version.

The latest release is always tagged with `latest`. Should you use this
tag, then run these commands to upgrade to newer images:

``` bash
$ docker-compose down
$ docker-compose pull
$ docker-compose up --force-recreate --build -d
```

## Backups

When running the docker compose setup, you can use the following to
backup the database.

1. (Optionally) Stop docspell, for example with `docker-compose down`.
   It is preferred to stop, i.e. should you upgrade versions.
2. Add a new file `docker-compose.override.yml` (next to your
   `docker-compose.yml`) with this content:

   ```yml
   version: '3.8'
   services:

   db:
     volumes:
       - /some/backupdir:/opt/backup
   ```

   The `/some/backupdir` is the directory where the backup should be stored on the host.
3. If you stopped the containers in step 1, start now  **only** the db service via `docker-compose up -d -- db`
4. Run the dump command:
   ```
   docker exec -it postgres_db pg_dump -d dbname -U dbuser -Fc -f /opt/backup/docspell.sqlc
   ```

The `docker-compose.override.yml` file is only to mount a local
directory into the db container. You can also add these lines directly
into the `docker-compose.yml`. Now you have the dump in your local
`/some/backupdir` directory.

This dump can be restored almost the same way. Mount your backup
directory into the db container as before in steps 1-3. Then run this
command in step 4 instead:

```
docker exec -it postgres_db pg_restore -d dbname -U dbuser -Fc /opt/backup/docspell.sqlc
```

So, before the upgrade run steps 1 to 4. Then you have a dump of your
current database (everything, files and all other data). When creating
and restoring a dump, do not start the docspell containers - make sure
to start the db container only.
