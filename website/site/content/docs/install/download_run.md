+++
title = "Manual Installation"
weight = 22
+++

# Download and Run

You can install via zip or deb archives. Please see the
[prerequisites](@/docs/install/prereq.md) first.

## Using zip files

1. Download the two files:
   {{ zip_files() }}

2. Unzip both files:
   ``` bash
   $ unzip docspell-*.zip
   ```
3. Open two terminal windows and navigate to the the directory
   containing the zip files.
4. Start both components executing:
   ``` bash
   $ ./docspell-restserver*/bin/docspell-restserver
   ```

   in one terminal and

   ``` bash
   $ ./docspell-joex*/bin/docspell-joex
   ```

   in the other.
5. Point your browser to: <http://localhost:7880/app>
6. Register a new account, sign in and try it.

Note, that this setup doesn't include watching a directory nor
fulltext search. Using zip/deb files requires to take care of the
[prerequisites](@/docs/install/prereq.md) yourself.


## Using deb files

Please checkout this comprehensive
[guide](https://github.com/andreklug/docspell-debian) for installing
on a Debian system.

Packages are also provided at the release page:

{{ deb_files() }}

The DEB packages can be installed on Debian, or Debian based Distros:

``` bash
$ sudo dpkg -i docspell*.deb
```

Then the start scripts are in your `$PATH`. Run `docspell-restserver`
or `docspell-joex` from a terminal window.

The packages come with a systemd unit file that will be installed to
autostart the services.


# Running

Run the start script (in the corresponding `bin/` directory when using
the zip files):

```
$ ./docspell-restserver*/bin/docspell-restserver
$ ./docspell-joex*/bin/docspell-joex
```

This will startup both components using the default configuration.
Please refer to the [configuration
page](@/docs/configure/main.md) for how to create a custom
config file. Once you have your config file, simply pass it as
argument to the command:

```
$ ./docspell-restserver*/bin/docspell-restserver /path/to/server-config.conf
$ ./docspell-joex*/bin/docspell-joex /path/to/joex-config.conf
```

After starting the rest server, you can reach the web application
`http://localhost:7880/`.

You should be able to create a new account and sign in. When creating
a new account, use the same name for collective and user and then
login with this name.

## Upgrading

Since [downgrading](@/docs/install/downgrading.md) is not supported,
it is recommended to backup your database before upgrading. Should
something not work as expected, restore the database backup and go
back to the previous version.

When using the zip or deb files, either install the new deb files via
your package manager or download and unpack the new zip files. You
might want to have a look at the changelog, since it is sometimes
necessary to modify the config file.

## Backup & Restore

There are several supported [databases](https://docspell.org/docs/configure/database/) but PostgreSQL is recommended for Docspell.

First to prevent any currently queued data from being lost, it's good practice to 
shutdown `docspell-joex` and `docspell-restserver` system services
before taking a database backup of Docspell. In order to stop Docspell, 
you need to perform these on the system that docspell is running on.
```bash
sudo systemctl stop docspell-joex
sudo systemctl stop docspell-restserver
```

Next, you can become the `postgres` user or database admin user on 
your PostgreSQL server/microservice and backup the database.
Note that this will take some time to complete depending on the size of your database.
We'll assume in our guide example that `docspelldb` is the name of your database:
```bash
pg_dump docspelldb > docspelldb_backup.sql
```

Optionally, once the docspell backup is complete you can 
use `rsync` or `scp` to send `docspelldb_backup.sql` to a backup server.
Now that you have known backup(s) of Docspell's database, you may one day have to restore this backup. 

Let's test try restoring it. You can start a PostgreSQL shell by using 
the `psql` command as the `postgres` user or a PostgreSQL admin account. 
If the database is corrupted or still exists, you will first need to remove it.
Warning: By performing this next step you are **deleting** your database.
```sql
DROP DATABASE docspelldb;
```

And now we'll create a new database for your backup to restore to.
Optionally, you can add UTF-8 encoding for better multilingual support.
This example will assume the owner of the database is named `docspell`.
```sql
CREATE DATABASE docspelldb WITH OWNER = 'docspell' ENCODING = 'UTF8' template = 'template0';
```

Now that we have a new database, we can restore the backup.
Exit your database with `\q` and in bash execute the following
commands as the `postgres` or admin user.
This command will also take some time to complete.
```bash
psql docspelldb < docspelldb_backup.sql
```

Now your database should be fully restored from your backup!
Let's go to the Docspell server and restart the Docspell services.
```bash
sudo systemctl start docspell-joex
sudo systemctl start docspell-restserver
```

If your database and owner are the same as your initial configuration,
and you see your docspell data restored, you have sucessfully restored
your PostgreSQL backup of Docspell manually.

### Fulltext Search

Fulltext search can also be powered by [SOLR](https://solr.apache.org). 
You need to install solr and create a core for docspell. Then cange the
solr url for both components (restserver and joex) accordingly. See
the relevant section in the [config page](@/docs/configure/fulltext-search.md).

### Watching a directory

The [dsc](@/docs/tools/cli.md) tool with the `watch` subcommand can be
used for this. Using systemd or something similar, it is possible to
create a system service that runs the script in "watch mode".
