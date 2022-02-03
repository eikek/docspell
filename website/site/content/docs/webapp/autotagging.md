+++
title = "Auto Tagging"
weight = 90
[extra]
mktoc = true
+++

# Auto-Tagging

Auto-Tagging must be enabled in the collective profile. Docspell can
go through your items periodically and learn from your existing tags.
But not all tags are suited for learning. Docspell can only learn
relationships between tags and the document's extracted text. Thus,
all tags that don't relate to the contents of a documents, should be
excluded.

For example, assume there is a tag `Done` that is associated to all
items that have been worked on. Over time, most of the items have this
tag. Whether an item is tagged with `Done` or not cannot be well
determined by looking at the text of the document. It would mean that
Docspell could learn relationships that are not correct and then tag
the next incoming items with `Done`.

{{ figure2(light="collective-settings-autotag.png", dark="collective-settings-autotag_dark.png") }}

That is why you need to specify what tags to learn. This is done by
defining whitelist or a blacklist of tag categories. When defining a
whitelist, then only tags in these categories are selected for
learning. When defining a blacklist, all tags *except* the one in the
list are chosen for learning.

The *Schedule* allows to define at what intervals tags should be
learned. When clicking the *Start Now* button, the task is submitted
immediately.
