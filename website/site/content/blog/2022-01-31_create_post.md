+++
title = "Create a new post"
[extra]
author = "eikek"
+++

# Create a new post

Sharing ideas and tips is very much welcome, if you like you can
create a small (or large) post here. You'll need `git` and potentially
a `github` account to make this convenient.

<!-- more -->

The contents of this website is maintained in the [<i class="fab fa-github ml-1"></i> git
repository](https://github.com/eikek/docspell) in the `website/site`
folder. It is build by the static site generator
[zola](https://www.getzola.org/) from a set of
[markdown](https://www.markdownguide.org/basic-syntax) files.

It is not necessary to know how everything is connected, you only need
to edit or create markdown files at some specific location. Here are
some proposals how to add or edit pages and getting them published to
docspell.org.

## Where to create the files

The contents of the published website is in the branch `current-docs`.
You should base your changes on this branch.

All blog pages go into this directory: `website/site/content/blog/`.
In this directory each post is a markdown file named by this pattern:

```
<year>-<month>-<day>_title_with_underscores.md
```

For example, this page here is named `2022-01-31_create_post.md`.

## Write on Github

A very convenient way is to edit and create posts directly on github
in the browser. All pages contain a small `Edit` link at the bottom
that takes you directly into edit model of the corresponding file on
github.

To create a new file on github, you can use this link:

<https://github.com/eikek/docspell/new/current-docs/website/site/content/blog>

It will present a form that lets you create a new file with content.
Once you commit this change, the project will be forked into your
account and the change is applied to this new fork. Then you can
create a pull request into this repository in order to publish it.

Plase see [below](#content) for how to start writing content.

## Writing locally

The preferred approach is to explicitely fork the repository and clone
it to your machine to do the modification. The big advantage is, that
you can look at the results while writing.

If you want to see a live view of the page while editing, some tools
are required. The easiest way to get these is to install
[nix](https://nixos.org/) and run `nix develop .#dev-vm` to get an
environment with all these tools installed. Otherwise install the
programs: [yarn](https://yarnpkg.com/),
[zola](https://www.getzola.org/), [elm](https://elm-lang.org) and
[sbt](https://scala-sbt.org).

Then clone the sources to your machine and build the complete site
once, so that all assets and required stuff is present:

```
sbt website/zolaBuildTest
```

Now you can use zola to start the page and watch for changes. The
changes are visible immediately without reloading the page in the
browser.

```
cd website/site && zola serve
```

This starts a web server on some port (usually `1111`); point your
browser to it and navigate to your new page. Whenever changes are
saved to the markdown file, the page refreshes automatically.

If styling is changed (in the css files or also sometimes when adding
new classes to HTML elements), a rebuild of the site css is necessary.
This can be done by running `scripts/run-styles.sh`. Via
`scripts/run-styles.sh --watch` it is possible to watch for these
changes as well. But it shouldn't be necessary to do large edits to
the css.

# Content

## Front matter

The very beginning of such a markdown file contains some metadata.
Start each page with these lines:

```markdown
+++
title = "Title of the post"
[extra]
author = "<your name>"
authorLink = "https://some-url"
+++

# First heading…
```

The front matter is the first part enclosed in `+++`. See
[zola](https://www.getzola.org/documentation/content/page/)
documentation for more details.

The `author` and `authorLink` setting is optional. You can leave out
the complete `[extra]` section. If `authorLink`is defined, the author
is rendered as a link to that URL. If `author` is missing, it defaults
to "_Unknown_".

## Elements

The content is styled automatically and the post is added to the list
on the main blog page. Additional to the standard markdown formatting,
there are some more usefull elements.

### Linking

If you want to link to an internal page, use markdown links where the
path is formatted like this:

```markdown
[link title](@/path/to/markdown_file.md)
```

Using the `@/path` style, zola generates the correct final link (and
checks for dead links).

### Info and warning boxes

There are small templates available to format a basic info or warning
box message.

```markdown
{%/* infobubble(title="My Title") */%}
Your content here ….
{%/* end */%}
```

For a box more styled like a warning, replace `info` with `warning`.

```markdown
{%/* warningbubble(title="My Title") */%}
Your content here ….
{%/* end */%}
```

This will render into:

{% infobubble(title="My Title") %}
Your content here ….
{% end %}

{% warningbubble(title="My Title") %}
Your content here ….
{% end %}

### Summary

In order to get a decent summary in the list of posts, you need to set
a marker in your file. Place a line containing only

```
<!-- more -->
```

into your file and everything before it will be rendered as a summary
on the blog listing.


### Buttons

Styled buttons can be created using HTML inside the markdown file:

```markdown
<a class="no-default button1" href="#">Click!</a>
```

Turns into:

<a class="no-default button1" href="#">Click!</a>


### Images

In image to appear on the whole page, use HTML with a `figure` tag:

```
<figure>
  <img src="image-url.jpg">
</figure>
```

<figure>
  <img src="/img/jesse-gardner-EqdpXeemf58-unsplash.jpg" >
</figure>

The site has a light and dark mode and sometimes it's nice to provide
images for both variants. You can use HTML for this and a specific
class per theme:

```html
<figure class="dark-block">
    <img src="dark-image.jpg" >
</figure>
<figure class="light-block">
    <img src="light-image.jpg" >
</figure>
```

See the effect when changing the theme:

<figure class="dark-block">
    <img src="/img/tersius-van-rhyn-xcQWMPm9fG8-unsplash.jpg" >
</figure>
<figure class="light-block">
    <img src="/img/cassie-boca-x-tbVqkfQCU-unsplash.jpg" >
</figure>

This can be done via a template if the file is next to the markdown
file in the same directory:

```markdown
{{/* figure2(light="light-image.jpg", dark="dark-image.jpg") */}}
```

<div class="text-sm text-right opacity-80">
Pictures are from <a href="https://unsplash.com" target="_blank">Unsplash</a>.
</div>

# Publish

Open a pull request against the `current-docs` branch. When the pull
request is merged, the publishing process starts automatically and the
content is available minutes after.
