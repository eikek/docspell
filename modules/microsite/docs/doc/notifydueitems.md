---
layout: docs
title: Notify about due items
permalink: doc/notifydueitems
---

# {{page.title}}

Each user that provides valid email (smtp) settings, can be notified
by docspell about due items. You will then receive an e-mail
containing a list of items, sorted by their due date.

You need first define smtp settings, please see [this
page](mailitem#e-mail-settings).

Notifying works simply by searching for due items periodically. It
will be submitted to the job queue and is picked up by an available
[job executor](joex) eventually. This can be setup in the user
settings page.

<div class="thumbnail">
  <img src="../img/notify-due-items.jpg">
</div>

At first, the task can be disabled/enabled any time.

Then two settings are required for sending an e-mail. You need to
specify the connection to use and the recipients.

It follows some settings to customize the query for searching items.
You can choose to only include items that have one or more tags (these
are `and`-ed, so all tags must exist on the item). You can also
provide tags that must *not* appear on an item (these tags are
`or`-ed, so only one such tag is enough ot exclude an item). A common
use-case would be to manually tag an item with *Done* once there is
nothing more to do. Then these items can be excluded from the search.
The somewhat inverse use-case is to always tag items with a *Todo* tag
and remove it once completed.

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

The *Schedule* field specifies the periodicity. The syntax is similiar
to a date-time string, like `2019-09-15 12:32`, where each part is a
pattern to also match multple values. The ui tries to help a little by
displaying the next two date-times this task would execute. A more in
depth help is available
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

You can see the task executing at the [processing page](processing).
