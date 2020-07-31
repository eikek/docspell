+++
title = "Encryption"
weight = 40
+++


# Context and Problem Statement

Since docspell may store important documents, it should be possible to
encrypt them on the server. It should be (almost) transparent to the
user, for example, a user must be able to login and download a file in
clear form. That is, the server must also decrypt them.

Then all users of a collective should have access to the files. This
requires to share the key among users of a collective.

But, even when files are encrypted, the associated meta data is not!
So especially access to the database would allow to see tags,
associated persons and correspondents of documents.

So in short, encryption means:

- file contents (the blobs and extracted text) is encrypted
- metadata is not
- secret keys are stored at the server (protected by a passphrase),
  such that files can be downloaded in clear form


# Decision Drivers

* major driver is to provide most possible privacy for users
* even at the expense of less features; currently I think that the
  associated meta data is enough for finding documents (i.e. full text
  search is not needed)

# Considered Options

It is clear, that only blobs (file contents) can be encrypted, but not
the associated metadata. And the extracted text must be encrypted,
too, obviously.


## Public Key Encryption (PKE)

With PKE that the server can automatically encrypt files using
publicly available key data. It wouldn't require a user to provide a
passphrase for encryption, only for decryption.

This would allows for first processing files (extracting text, doing
text analyisis) and encrypting them (and the text) afterwards.

The public and secret keys are stored at the database. The secret key
must be protected. This can be done by encrypting the passphrase to
the secret key using each users login password. If a user logs in, he
or she must provide the correct password. Using this password, the
private key can be unlocked. This requires to store the private key
passphrase encrypted with every users password in the database. So the
whole security then depends on users password quality.

There are plenty of other difficulties with this approach (how about
password change, new secret keys, adding users etc).

Using this kind of encryption would protect the data against offline
attacks and also for accidental leakage (for example, if a bug in the
software would access a file of another user).


## No Encryption

If only blobs are encrypted, against which type of attack would it
provide protection?

The users must still trust the server. First, in order to provide the
wanted features (document processing), the server must see the file
contents. Then, it will receive and serve files in clear form, so it
has access to them anyways.

With that in mind, the "only" feature is to protect against "stolen
database" attacks. If the database is somehow leaked, the attackers
would only see the metadata, but not real documents. It also protects
against leakage, maybe caused by a pogramming error.

But the downside is, that it increases complexity *a lot*. And since
this is a personal tool for personal use, is it worth the effort?


# Decision Outcome

No encryption, because of its complexity.

For now, this tool is only meant for "self deployment" and personal
use. If this changes or there is enough time, this decision should be
reconsidered.
