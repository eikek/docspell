+++
title = "Documentation"
weight = 0
+++

# Documentation

## About

Docspell's documentation primarily lives on this website, but
there is also valuable information contained with in the main
[README.md](https://github.com/eikek/docspell/blob/master/README.md)
and [various other
READMEs](https://github.com/search?q=repo%3Aeikek%2Fdocspell+path%3A.md+NOT+path%3A%2F%5Ewebsite%5C%2Fsite%5C%2F%2F&type=code)
in the repository.

## Contributing

First, please take a look at the ["Documentation" portion of the
README](https://github.com/eikek/docspell/blob/master/Contributing.md#Documentation).

Please note that the documentation hosted at https://docspell.org/ is for
the current version of Docspell and will not reflect any unreleased changes
to the code or documentation. Given that, before proposing a documentation
improvement, please check the latest version of the documentation (on the
`master` branch) to avoid potentially duplicating effort.

### Simple Changes

If you would like to contribute to this documentation website, simple edits
to existing pages can be made by clicking the "Edit" button at the bottom
of the live website page you wish to propose changes to. Doing so will take
you to GitHub where you can make your changes, commit them to a branch on
your fork of the repository, and ultimately create a pull request to get
them reviewed and merged into the official documentation.

Similarly, READMEs in the `docspell` repository can be made by opening
the file on GitHub and clicking the "Edit" icon. New files can be added as
well. The process is then the same as above.

Of course, if you would like to make your changes locally or make more complex
changes, you can fork the repository, clone your fork, make your changes,
push them to the fork, and then open a pull request.

### Local Preview

If you would like to also preview your local changes, you can do so as follows.

The subsequent commands assume you have already locally cloned the repository
(or a fork), and have a working development environment.

```bash
# in repository root
sbt website/zolaBuild
cd website/site && zola serve
```

As you write changes to the website content (to disk), Zola will live-reload
the site.
