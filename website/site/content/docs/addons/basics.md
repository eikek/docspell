+++
title = "Basics"
insert_anchor_links = "right"
description = "Docspell Addons."
weight = 10
template = "docs.html"
+++

# Addons

Addons allow to execute custom software within a defined context in
Docspell. The idea is to be able to support new features and amend
existing ones.

{% warningbubble(title="Experimental") %} Addons are considered
experimental. The interaction between addons and Docspell is still
subject to change.

The intended audience for addons are developers (to create addons) and
technically inclined users to install, configure and use them.
{% end %}

Despite the warning above, addons are a nice way to amend your
docspell server with new things, you are encouraged to try it out and
give feedback ;-).

{% infobubble(title="Enable addons manually") %}
Addons are disabled by default. They must be enabled in the config
file of the restserver!
{% end %}


## What is an Addon?

An addon is a zip file that contains a `docspell-addon.yml` (or .yaml
or .json) file in its root. The `docspell-addon.yml` is the *addon
descriptor* telling how to run and optionally build the addon. In the
ZIP file, an addon provides a program that expects one argument which
is a file containing the user input for the addon. Addons can
communicate back to docspell via their stdout and/or via directly
calling the docspell server as part of their program.


## What can Addons do?

Addons can accept user input and are arbitrary external programs that
can do whatever they want. However, Docspell can embed running addons
in restricted environments, where they don't have network for example.
Addons can safely communicate to Docspell via their stdout output
returning instructions that Docspell will realise.

Running addons is managed by docspell. Currently they can be executed:

- as the final step when processing or re-procssing an item. They then
  have access to all the item data that has been collected during
  processing (id, extracted text, converted pdfs, etc) and it can work
  with that. It may, for example, set more tags or custom fields.
- trigger manually on some existing item
- periodically defined by a schedule. This executes the addons only
  with the configured user input.
- … (maybe more to come)

Since an addon may not make sense to run on all these situations, it
must define a sensible subset via the `triggers` option in its
descriptor.


## How are they run

Addons are always executed by the joex component as an external
process, therefore they can be written in any programming or scripting
language.

That means the machine running joex possibly needs to match the
requirements of each addon. To ease this, addons can provide a [nix
descripton](https://nixos.wiki/wiki/Flakes) or a `Dockerfile`. Then
you need to prepare the machine only with two things (nix and docker)
to have the prerequisites for running many addons.


# More …

Addons are a flexible way to extend Docspell and require some
technical affinity. However, only "using" addons should not be that
hard, but it will always depend on the documentation of the addon and
its own complexity.

As the user, you may have different views: preparing the server to be
able to run addons, writing your own addons and finally using them

The following sections are divided these perspectives:

## Using Addons

Addons must be installed and then configured in order before they can
be used. [Using Addons](@/docs/addons/using.md) describes this
perspective.

{{ buttonright(href="/docs/addons/using", text="More…") }}

## Control how addons are run

As the owner of your server, you want to [control how addons are
run](@/docs/addons/control.md). Since addons are arbitrary programs,
potentially downloaded from the internet, they can be run in a
restricted environment.

{{ buttonright(href="/docs/addons/control", text="More…") }}


## Write custom addons

Finally, [writing addons](@/docs/addons/writing.md) requires (among
other things) to know how to interact with Docspell and what package
format is expected.

{{ buttonright(href="/docs/addons/writing", text="More…") }}



<!-- ## Goals -->

<!-- - Convenient for addon creators. Addons can be written in any -->
<!--   programming language and have a very light contract: they receive -->
<!--   one input argument and _may_ return structured data to instruct -->
<!--   docspell what to do. If not they can execute abritrary code to call -->
<!--   the server directly. -->
<!-- - Server administrators control how they are executed. Since addons -->
<!--   may run anything, the execution should be able to locked down when -->
<!--   wanted. -->
<!-- - Users can install and configure addons via the web interface easily. -->
<!--   It should be easy for addon creators to document how users can use -->
<!--   them. -->


<!-- # TODOs -->

<!-- - what if joex is running inside a container alread? -->
<!-- - some use cases: -->
<!--   - I want an addon to do some stuff when processing files -->
<!--     - my files named "something_bla" are always this specific document -->
<!--       and so very specific processing would be great -->
<!--   - I want XYZ files to work (e.g. mp3?) -->
<!--   - I want to generate previews for video files -->
<!-- - Example Addons: -->
<!--   - swiss qr code detection on invoices -->
<!--   - tags via regexes -->
<!--   - text extraction from audio? -->
<!--   - preview generation for video? -->
