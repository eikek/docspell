+++
title = "Customize Item Card"
weight = 39
+++

# Customize item card

The search view or list view displays the search results as a list of
item cards. Each cards represents one item.

The item card can be customized a bit in the user settings. In the
user menu (the user icon, top right), choose _User Profile_ and then
_UI Settings_. Among other things, there is a _Item Cards_ section:

{{ figure2(light="itemcard-customize-01.png", dark="itemcard-customize-01_dark.png") }}

### Max Note Length

This defines how many of the item notes to display in the card. You
can set it to `0` to not show any notes at all. This is only a "soft
limit", there is also a "hard limit" in [docspell's
configuration](@/docs/configure/defaults.md#rest-server) (see
`max-note-length`), that is an upper limit to this value.

### Size of item preview

The item preview is an image of the first page of the first
attachment. You can change the order of attachments in the item detail
view. This image has a predefined size, which is specified [docspell's
configuration](@/docs/configure/defaults.md#joex) (see
`extraction.preview.dpi`). The size for displaying it, can be
specified via this setting. A _small_ preview uses about 80px width, a
_medium_ one 160px and _large_ means to use the available space in the
card.

<div class="grid grid-cols-3 gap-4">
    <div class="">
      {{ imgnormal(file="itemcard-customize-04.png", width="300")}}
    </div>
    <div class="">
      {{ imgnormal(file="itemcard-customize-03.png", width="300")}}
    </div>
    <div class="">
      {{ imgnormal(file="itemcard-customize-02.png", width="300")}}
    </div>
</div>


### Card Title/Subtitle Pattern

Allows to define a pattern to customize the appearance of title and
subtitle of each card. Variables expressions are enclosed in `{{` and
`}}`, other text is used as-is. The following variables are available:

- `{{name}}` the item name
- `{{source}}` the source the item was created from
- `{{folder}}` the items folder
- `{{corrOrg}}` the correspondent organization
- `{{corrPerson}}` the correspondent person
- `{{correspondent}}` organization and person separated by a comma
- `{{concPerson}}` the concerning person
- `{{concEquip}}` the concerning equipment
- `{{concerning}}` person and equipment separated by a comma
- `{{fileCount}}` the number of attachments of this item
- `{{dateLong}}` the item date as full formatted date (_Tue, December 12nd, 2020_)
- `{{dateShort}}` the item date as short formatted date (_yyyy/mm/dd_)
- `{{dueDateLong}}` the item due date as full formatted date (_Tue, December 12nd, 2020_)
- `{{dueDateShort}}` the item due date as short formatted date (_yyyy/mm/dd_)
- `{{direction}}` the items direction values as string

You can combine multiple variables with `|` to use the first non-empty
one, for example `{{corrOrg|corrPerson|-}}` would render the
organization and if that is not present the person. If both are absent
a dash `-` is rendered. A part (like the `-` here) is rendered as is,
if it cannot be matched against a known variable.

The default patterns are:

- title: `{{name}}`
- subtitle: `{{dateLong}}`
