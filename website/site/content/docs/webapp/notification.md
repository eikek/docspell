+++
title = "Notifications"
weight = 60
[extra]
mktoc = true
+++

# Notifications

Docspell can notify on specific events and it can run queries
periodically and notify about the result.

Notification can be configured per user: go to *User profile →
Notifications*. You can choose between webhooks and two periodic
queries. Webhooks are HTTP requests that are immediatly executed when
some event happens in Docspell, for example a tag was added to an
item. Periodic queries can be used for running queries regularly and
get the result sent as message.

Both require to first select a channel, for how the message should be
sent. This can be done in *User profile → Notification Channels*.


## Channels

Channels are means to deliver a message. Currently, docspell supports
these channels:

- E-Mail; you need to define SMTP settings
  [here](@/docs/webapp/emailsettings.md#smtp-settings)
- HTTP Requests: another option is to execute a generic HTTP request
  with all event data in a JSON body.
- [Matrix](https://matrix.org)
- [Gotify](https://gotify.net)

<div class="justify-center flex">
{{ imgnormal2(light="notification-01.png", dark="notification-01_dark.png", width="250px") }}
</div>


### Matrix

Matrix is an open network for secure and decentralized communication.
It relies on open standards and can be self-hosted.

To receive messages into your matrix room, you need to give the room
id, your access key and the url of your home server, for example
`https://matrix.org`.

You can find the room id in your room settings under "Advanced" in
Element. The access key is in your user settings under tab "Help &
About" in Element.

{{ figure2(light="notification-02.png", dark="notification-02_dark.png") }}

### Gotify

Gotify is a simple application for receiving messages to be notified
on several clients via websockets. It is great for connecting
applications to your devices.

It requires only your gotify url and the application secret.

{{ figure2(light="notification-03.png", dark="notification-03_dark.png") }}


### E-Mail

E-Mails are sent using one of your configured [SMTP
connections](@/docs/webapp/emailsettings.md#smtp-settings).

The part `docspell.joex.send-mail.list-id` in joex' configuration file
can be used to add a `List-Id` mail header to every notification mail.

### HTTP Request

The most generic form is the channel *HTTP Request*. This just sends a
POST request to a configured endpoint. The requests contains a JSON
body with the event details.

## Webhooks

Webhooks are http requests that are generated on specific events in
Docspell.

### Events

You need to choose which events you are interested in.

{{ figure2(light="notification-04.png", dark="notification-04_dark.png") }}

You can do so by selecting multiple event types or by clicking the
*Notify on all events* checkbox.

Each event type generates different event data. This data is prepared
as a JSON structure which is either send directly or used to generate
a message from it.

Additionally, it is possible to filter the events using an expression
that is applied to the event data JSON structure.

Events can be send to multiple channels.

### Testing

The webhook form allows you to look at some sample events. These
events are generated from random data and show how the message would
look like (roughly, because it obviously depends on how the channel
displays it).

You can also click the *Test Delivery* button. This generates a sample
event of the first of the selected event (or some chosen one, if
*Notify on all events* is active) and sends it via the current
channel.

### JSON filter expression

This filter allows to further constrain the events that trigger a
notification. For example, it can be used to be notified only when
tags of a specific category are changed.

It works by selecting paths into the JSON structure of the event. Thus
you need to know this structure, in order to define this expression. A
good way is to look at the sample events for the *HTTP Request*
channel. These show the exact JSON structure that this filter is
applied to (that applies to every channel).

{{ figure2(light="notification-05.png", dark="notification-05_dark.png") }}

As an example: Choose the event *TagsChanged* and this filter
expression: `content.added,removed.category=document_type` to be
notified whenever a tag is added or removed whose category is
`document_type`.

Please see [this page](@/docs/jsonminiquery/_index.md) for details
about it.

{% infobubble(title="Note") %}
The webhook feature is still experimental. It starts out with only a
few events to choose from and the JSON structure of events might
change in next versions.
{% end %}

# Periodic Queries

These are [background tasks](@/docs/joex/_index.md) that execute a
defined query. If the query yields a non-empty result, the result is
converted into a message and sent to the specified target system.

For example, this can be used to regularly inform about due items, all
items tagged *Todo* etc.

## Due Items Task

{{ figure2(light="notification-06.png", dark="notification-06_dark.png") }}

The settings allow to customize the query for searching items. You can
choose to only include items that have one or more tags (these are
`and`-ed, so all tags must exist on the item). You can also provide
tags that must *not* appear on an item (these tags are `or`-ed, so
only one such tag is enough ot exclude an item). A common use-case
would be to manually tag an item with *Done* once there is nothing
more to do. Then these items can be excluded from the search. The
somewhat inverse use-case is to always tag items with a *Todo* tag and
remove it once completed.

The *Remind Days* field species the number of days the due date may be
in the future. Each time the task executes, it searches for items with
a due date lower than `today + remindDays`.

If you don't restrict the search using tags, then all items with a due
date lower than this value are selected. Since items are (usually) not
deleted, this only makes sense, if you remove the due date once you
are done with an item.

The last option is to check *cap overdue items*, which uses the value
in *Remind Days* to further restrict the due date of an item: only
those with a due date *greater than* `today - remindDays` are
selected. In other words, only items with an overdue time of *at most*
*Remind Days* are included.

## Generic Query Task

This is the generic version of the *Due Items Task*. Instead of
selecting the items via form elements, you can define a custom
[query](@/docs/query/_index.md) and optionally in combination with a
[bookmark](@/docs/webapp/bookmarks.md).

{{ figure2(light="notification-07.png", dark="notification-07_dark.png") }}

### Schedule

Both tasks have a *Schedule* field to specify the periodicity of the
task. The syntax is similiar to a date-time string, like `2019-09-15
12:32`, where each part is a pattern to also match multple values. The
ui tries to help a little by displaying the next two date-times this
task would execute. A more in depth help is available
[here](https://github.com/eikek/calev#what-are-calendar-events). For
example, to execute the task every monday at noon, you would write:
`Mon *-*-* 12:00`. A date-time part can match all values (`*`), a list
of values (e.g. `1,5,12,19`) or a range (e.g. `1..9`). Long lists may
be written in a shorter way using a repetition value. It is written
like this: `1/7` which is the same as a list with `1` and all
multiples of `7` added to it. In other words, it matches `1`, `1+7`,
`1+7+7`, `1+7+7+7` and so on.

You can click on *Start Once* to run this task right now, without
saving the form to the database ("right now" means it is picked up by
a free job executor).

If you click *Submit* these settings are saved and the task runs
periodically.

You can see the task executing at the [processing
page](@/docs/webapp/processing.md).
