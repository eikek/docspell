+++
title = "Directory Cleaner"
description = "Clean directories from files in docspell"
weight = 32
+++

# Introduction

This script is made for cleaning up the consumption directory used for
the consumedir service (as it is provided as docker container)which
are copied or moved there.

<https://github.com/eikek/docspell/tree/master/tools/consumedir-cleaner>

## How it works

- Checks for every file (in the collective's folder of the given user
  name) if it already exists in the collective (using Docspell's API).
- If so, by default those files are moved to an archive folder just
  besides the collective's consumption folders named _archive. The
  archive's files are organized into monthly subfolders by the date
  they've been added to Docspell
  - If set, those files can also be deleted instead of being moved to
    the archive. There is no undo function provided for this, so be
    careful.
- If a file is found which does not exist in the collective, by
  default nothing happens, so that file would be found in every run
  and just ignored
  - If set, those files can also be uploaded to Docspell. Depending on
    the setting for files already existing these files would either be
    deleted or moved to the archive in the next run.

## Usage (parameters / settings)

Copy the script to your machine and run it with the following
parameters:

1. URL of Docspell, including http(s)
2. Username for Docspell, possibly including Collective (if other name
   as user)
3. Password for Docspell
4. Path to the directory which files shall be checked against
   existence in Docspell

Additionally, environment variables can be used to alter the behavior:

- `DS_CC_REMOVE`
  - `true` – delete files which already exist in the collective
  - `false` (default) - move them to the archive (see above)
- `DS_CC_UPLOAD_MISSING`
  - `true` - uploads files which do not exist in the collective
  - `false` (default) - ignore them and do nothing
