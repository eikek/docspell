+++
title = "Periodic Tasks"
weight = 130
+++

# Context and Problem Statement

Currently there is a `Scheduler` that consumes tasks off a queue in
the database. This allows multiple job executors running in parallel
racing for the next job to execute. This is for executing tasks
immediately – as long as there are enough resource.

What is missing, is a component that maintains periodic tasks. The
reason for this is to have house keeping tasks that run regularily and
clean up stale or unused data. Later, users should be able to create
periodic tasks, for example to read e-mails from an inbox or to be
notified of due items.

The problem is again, that it must work with multiple job executor
instances running at the same time. This is the same pattern as with
the `Scheduler`: it must be ensured that only one task is used at a
time. Multiple job exectuors must not schedule a perdiodic task more
than once. If a periodic tasks takes longer than the time between
runs, it must wait for the next interval.


# Considered Options

1. Adding a `timer` and `nextrun` field to the current `job` table
2. Creating a separate table for periodic tasks

## Decision Outcome

The 2. option.

For internal housekeeping tasks, it may suffice to reuse the existing
`job` queue by adding more fields such that a job may be considered
periodic. But this conflates with what the `Scheduler` is doing now
(executing tasks as soon as possible while being bound to some
resource limits) with a completely different subject.

There will be a new `PeriodicScheduler` that works on a new table in
the database that is representing periodic tasks. This table will
share fields with the `job` table to be able to create `RJob` records.
This new component is only taking care of periodically submitting jobs
to the job queue such that the `Scheduler` will eventually pick it up
and run it. If the tasks cannot run (for example due to resource
limitation), the periodic scheduler can't do nothing but wait and try
next time.

```sql
CREATE TABLE "periodic_task" (
  "id" varchar(254) not null primary key,
  "enabled" boolean not null,
  "task" varchar(254) not null,
  "group_" varchar(254) not null,
  "args" text not null,
  "subject" varchar(254) not null,
  "submitter" varchar(254) not null,
  "priority" int not null,
  "worker" varchar(254),
  "marked" timestamp,
  "timer" varchar(254) not null,
  "nextrun" timestamp not null,
  "created" timestamp not null
);
```

Preparing for other features, at some point periodic tasks will be
created by users. It should be possible to disable/enable them. The
next 6 properties are needed to insert jobs into the `job` table. The
`worker` field (and `marked`) are used to mark a periodic job as
"being worked on by a job executor".

The `timer` is the schedule, which is a
[systemd-like](https://man7.org/linux/man-pages/man7/systemd.time.7.html#CALENDAR_EVENTS)
calendar event string. This is parsed by [this
library](https://github.com/eikek/calev). The `nextrun` field will
store the timestamp of the next time the task would need to be
executed. This is needed to query this table for the newest task.

The `PeriodicScheduler` works roughly like this:

On startup:
- Remove stale worker values. If the process has been killed, there
  may be marked tasks which must be cleared now.

Main-Loop:
0. Cancel current scheduled notify (see 4. below)
1. get next (= earliest & enabled) periodic job
2. if none: stop
3. if triggered (= `nextrun <= 'now'`):
  - Mark periodic task. On fail: goto 1.
  - Submit new job into the jobqueue:
    - Update `nextrun` field
    - Check for non-final jobs of that name. This is required to not
      run the same periodic task multiple times concurrently.
      - if exist: goto 4.
      - if not exist: submit job
  - Unmark periodic task
4. if future
  - schedule notify: notify self to run again next time the task
    schedule triggers
