# Start docspell quickly locally

This is a bash script to quickly run docspell on your local machine.
It requires [tmux](https://github.com/tmux/tmux) to be installed (and
some others: curl, unzip etc).

Any prerequisites are to be taken care of by yourself. Fulltext search
is disabled, unless a environment variable `DOCSPELL_SOLR_URL` exists.

A H2 database is used by default, unless a env variable `DOCSPELL_DB`
exists.

It then creates a configuration file, downloads docspell and starts
restserver and joex instances as given:

```bash
❯ # start one joex and one restserver, use version 0.32.0
❯ ./start-local.sh 0.32.0 1 1

❯ # start two joex and one restserver, use a nightly version
❯ ./start-local.sh 0.33.0-SNAPSHOT 1 2
```
