+++
title = "Export Files"
description = "Downloads all files from docspell."
weight = 65
+++

# export-files.sh

This script can be used to download all files from docspell that have
been uploaded before and the item metadata.

It downloads the original files, those that have been uploaded and not
the converted pdf files.

The item's metadata are stored next to the files to provide more
information about the item: corresponent, tags, dates, custom fields
etc. This contains most of your user supplied data.

This script is intended for having your data outside and independent
of docspell. Another good idea for a backup strategy is to take
database dumps *and* storing the releases of docspell next to this
dump.

Files are stored into the following folder structure (below the given
target directory):

```
- yyyy-mm (item date)
  - A3…XY (item id)
    - somefile.pdf (attachments with name)
    - metadata.json (json file with items metadata)
```

By default, files are not overwritten, it stops if existing files are
encountered. This and some other things can be changed using
environment variables:

- `DS_USER` the account name for login, it is asked if not available
- `DS_PASS` the password for login, it is asked if not available
- `OVERWRITE_FILE=` if `y` then overwriting existing files is ok.
  Default is `n`.
- `SKIP_FILE=` if `y` then existing files are skipped (supersedes
  `OVERWRITE_FILE`). Default is `n`.
- `DROP_ITEM=` if `y` the item folder is removed before attempting to
  download it. If this is set to `y` then the above options don't make
  sense, since they operate on the files inside the item folder.
  Default is `n`.

Docspell sends the sha256 hash with each file via the ETag header.
This is used to do a integrity check after downloading.


# Requirements

It is a bash script that additionally needs
[curl](https://curl.haxx.se/) and [jq](https://stedolan.github.io/jq/)
to be available.

# Usage

```
./export-files.sh <docspell-base-url> <target-directory>
```

For example, if docspell is at `http://localhost:7880`:

```
./export-files.sh http://localhost:7880 /tmp/ds-downloads
```

The script asks for your account name and password. It then logs in
and goes through all items downloading the metadata as json and the
attachments.


# Example Run

``` bash
fish> env SKIP_FILE=y DS_USER=demo DS_PASS=test ./export-files.sh http://localhost:7880 /tmp/download
Login to Docspell.
Using url: http://localhost:7880

Login successful
Downloading 73 items…
Get next items with offset=0, limit=100
Get item 57Znskthf3g-X7RP1fxzE2U-dwr4vM6Yjnn-b7s1PoCznhz
 - Download 'something.txt' (8HbeFornAUN-kBCyc8bHSVr-bnLBYDzgRQ7-peMZzyTzM2X)
 - Checksum ok.
Get item 94u5Pt39q6N-7vKu3LugoRj-zohGS4ie4jb-68bW5gXU6Jd
 - Download 'letter-en.pdf' (6KNNmoyqpew-RAkdwEmQgBT-QDqdY97whZA-4k2rmbssdfQ)
 - Checksum ok.
Get item 7L9Fh53RVG4-vGSt2G2YUcY-cvpBKRXQgBn-omYpg6xQXyD
 - Download 'mail.html' (A6yTYKrDc7y-xU3whmLB1kB-TGhEAVb12mo-RUw5u9PsYMo)
 - Checksum ok.
Get item DCn9UtWUtvF-2qjxB5PXGEG-vqRUUU7JUJH-zBBrmSeGYPe
 - Download 'Invoice_7340224.pdf' (6FWdjxJh7yB-CCjY39p6uH9-uVLbmGfm25r-cw6RksrSx4n)
 - Checksum ok.
…
```

The resulting directory looks then like this:

``` bash
…
├── 2020-08
│   ├── 6t27gQQ4TfW-H4uAmkYyiSe-rBnerFE2v5F-9BdqbGEhMcv
│   │   ├── 52241.pdf
│   │   └── metadata.json
│   └── 9qwT2GuwEvV-s9UuBQ4w7o9-uE8AdMc7PwL-GFDd62gduAm
│       ├── DOC-20191223-155707.jpg
│       └── metadata.json
├── 2020-09
│   ├── 2CM8C9VaVAT-sVJiKyUPCvR-Muqr2Cqvi6v-GXhRtg6eomA
│   │   ├── letter with spaces.pdf
│   │   └── metadata.json
│   ├── 4sXpX2Sc9Ex-QX1M6GtjiXp-DApuDDzGQXR-7pg1QPW9pbs
│   │   ├── analyse.org
│   │   ├── 201703.docx
│   │   ├── 11812_120719.pdf
│   │   ├── letter-de.pdf
│   │   ├── letter-en.pdf
│   │   └── metadata.json
│   ├── 5VhP5Torsy1-15pwJBeRjPi-es8BGnxhWn7-3pBQTJv3zPb
│   │   └── metadata.json
│   ├── 7ePWmK4xCNk-gmvnTDdFwG8-JcN5MDSUNPL-NTZZrho2Jc6
│   │   ├── metadata.json
│   │   └── Rechnung.pdf
…
```

The `metadata.json` file contains all the item metadata. This may be
useful when importing into other tools.

``` json
{
  "id": "AWCNx7tJgUw-SdrNtRouNJB-FGs6Y2VP5bV-218sFN8mjjk",
  "direction": "incoming",
  "name": "Ruecksendung.pdf",
  "source": "integration",
  "state": "confirmed",
  "created": 1606171810005,
  "updated": 1606422917826,
  "itemDate": null,
  "corrOrg": null,
  "corrPerson": null,
  "concPerson": null,
  "concEquipment": null,
  "inReplyTo": null,
  "folder": null,
  "dueDate": null,
  "notes": null,
  "attachments": [
    {
      "id": "4aPmhrjfR9Z-AgknoW6yVoE-YkffioD2KXV-E6Vm6snH17Q",
      "name": "Ruecksendung.converted.pdf",
      "size": 57777,
      "contentType": "application/pdf",
      "converted": true
    }
  ],
  "sources": [
    {
      "id": "4aPmhrjfR9Z-AgknoW6yVoE-YkffioD2KXV-E6Vm6snH17Q",
      "name": "Ruecksendung.pdf",
      "size": 65715,
      "contentType": "application/pdf"
    }
  ],
  "archives": [],
  "tags": [
    {
      "id": "EQvJ6AHw19Y-Cdg3gF78zZk-BY2zFtNTwes-J95jpXpzhfw",
      "name": "Hupe",
      "category": "state",
      "created": 1606427083171
    },
    {
      "id": "4xyZoeeELdJ-tJ91GiRLinJ-7bdauy3U1jR-Bzr4VS96bGS",
      "name": "Invoice",
      "category": "doctype",
      "created": 1594249709473
    }
  ],
  "customfields": [
    {
      "id": "5tYmDHin3Kx-HomKkeEVtJN-v99oKxQ8ot6-yFVrEmMayoo",
      "name": "amount",
      "label": "EUR",
      "ftype": "money",
      "value": "151.55"
    },
    {
      "id": "3jbwbep8rDs-hNJ9ePRE7gv-21nYMbUj3eb-mKRWAr4xSS2",
      "name": "invoice-number",
      "label": "Invoice-Nr",
      "ftype": "text",
      "value": "I454602"
    },
    {
      "id": "AH4p4NUCa9Y-EUkH66wLzxE-Rf2wJPxTAYd-DeGDm4AT4Yg",
      "name": "number",
      "label": "Number",
      "ftype": "numeric",
      "value": "0.10"
    }
  ]
}
```
