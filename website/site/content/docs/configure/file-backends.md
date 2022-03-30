+++
title = "File Backends"
insert_anchor_links = "right"
description = "Describes the configuration file and shows all default settings."
weight = 30
template = "docs.html"
+++

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
(see the [default configs](@/docs/configure/main.md#default-config)):

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
