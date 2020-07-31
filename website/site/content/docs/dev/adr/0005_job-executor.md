+++
title = "Joex - Job Executor"
weight = 60
+++

# Context and Problem Statement

Docspell is a multi-user application. When processing user's
documents, there must be some thought on how to distribute all the
processing jobs on a much more restricted set of resources. There
maybe 100 users but only 4 cores that can process documents at a
time. Doing simply FIFO is not enough since it provides an unfair
distribution. The first user who submits 20 documents will then occupy
all cores for quite some time and all other users would need to wait.

This tries to find a more fair distribution among the users (strictly
meaning collectives here) of docspell.

The job executor is a separate component that will run in its own
process. It takes the next job from the "queue" and executes the
associated task. This is used to run the document processing jobs
(text extraction, text analysis etc).

1. The task execution should survive restarts. State and task code
   must be recreated from some persisted state.

2. The processing should be fair with respect to collectives.

3. It must be possible to run many job executors, possibly on
   different machines. This can be used to quickly enable more
   processing power and removing it once the peak is over.

4. Task execution can fail and it should be able to retry those
   tasks. Reasons are that errors may be temporarily (for example
   talking to a third party service), and to enable repairing without
   stopping the job executor. Some errors might be easily repaired (a
   program was not installed or whatever). In such a case it is good
   to know that the task will be retried later.

# Considered Options

In contrast to other ADRs this is just some sketching of thoughts for
the current implementation.

1. Job description are serialized and written to the database into a
   table. This becomes the queue. Tasks are identified by names and a
   job executor implementation must have a map of names to code to
   lookup the task to perform. The tasks arguments are serialized into
   a string and written to the database. Tasks must decode the
   string. This can be conveniently done using JSON and the provided
   circe decoders.

2. To provide a fair execution jobs are organized into groups. When a
   new job is requested from the queue, first a group is selected
   using a round-robin strategy. This should ensure good enough
   fairness among groups. A group maps to a collective. Within a
   group, a job is selected based on priority, submitted time (fifo)
   and job state (see notes about stuck jobs).

3. Allowing multiple job executors means that getting the next job can
   fail due to simultaneous running transactions. It is retried until
   it succeeds. Taking a job puts in into _scheduled_ state. Each job
   executor has a unique (manually supplied) id and jobs are marked
   with that id once it is handed to the executor.

4. When a task fails, its state is updated to state _stuck_. Stuck
   jobs are retried in the future. The queue prefers to return stuck
   jobs that are due at the specific point in time ignoring the
   priority hint.

## More Details

A job has these properties

- id (something random)
- group
- taskname (to choose task to run)
- submitted-date
- worker (the id of the job executor)
- state, one of: waiting, scheduled, running, stuck, cancelled,
  failed, success
  - waiting: job has been inserted into the queue
  - scheduled: job has been handed over to some executore and is
    marked with the job executor id
  - running: a task is currently executing
  - stuck: a task has failed and is being retried eventually
  - cancelled: task has finished and there was a cancel request
  - failed: task has failed, execeeded the retries
  - success: task has completed successfully

The queue has a `take` or `nextJob` operation that takes the worker-id
and a priority hint and goes roughly like this:

- select the next group using round-robin strategy
- select all jobs with that group, where
  - state is stuck and waiting time has elapsed
  - state is waiting and have the given priority if possible
- jobs are ordered by submitted time, but stuck jobs whose waiting
  time elapsed are preferred

There are two priorities within a group: high and low. A configured
counting scheme determines when to select certain priority. For
example, counting scheme of `(2,1)` would select two high priority
jobs and then 1 low priority job. The `take` operation tries to prefer
this priority but falls back to the other if no job with this priority
is available.

A group corresponds to a collective. Then all collectives get
(roughly) equal treatment.

Once there are no jobs in the queue the executor goes into sleep and
must be waked to run again. If a job is submitted, the executors are
notified.

## Stuck Jobs

A job is going into _stuck_ state, if the task has failed. In this
state, the task is rerun after a while until a maximum retry count is
reached.

The problem is how to notify all executors when the waiting time has
elapsed. If one executor puts a job into stuck state, it means that
all others should start looking into the queue again after `x`
minutes. It would be possible to tell all existing executors to
schedule themselves to wake up in the future, but this would miss all
executors that show up later.

The waiting time is increased exponentially after each retry (`2 ^
retry`) and it is meant as the minimum waiting time. So it is ok if
all executors wakeup periodically and check for new work. Most of the
time this should not be necessary and is just a fallback if only stuck
jobs are in the queue and nothing is submitted for a long time. If the
system is used, jobs get submitted once in a while and would awake all
executors.
