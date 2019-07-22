---
layout: docs
title: Joex
---

# {{ page.title }}

Joex is short for *Job Executor* and it is the component managing long
running tasks in docspell. One of these long running tasks is the file
processing task.

One joex component handles the processing of all files of all
collectives/users. It requires much more resources than the rest
server component. Therefore the number of jobs that can run in
parallel is limited with respect to the hardware it is running on.

For larger installations, it is probably better to run several joex
components on different machines. That works out of the box, as long
as all components point to the same database and use different
`app-id`s (see [configuring docspell](./configure.html)).

When files are submitted to docspell, they are stored in the database
and all known joex components are notified about new work. Then they
compete on getting the next job from the queue. After a job finishes
and no job is waiting in the queue, joex will sleep until notified
again. It will also periodically notify itself as a fallback.

## Scheduler and Queue

The scheduler is the part that runs and monitors the long running
jobs. It works together with the job queue, which defines what job to
take next.

To create a somewhat fair distribution among multiple collectives, a
collective is first chosen in a simple round-robin way. Then a job
from this collective is chosen by priority.

There are only two priorities: low and high. A simple *counting
scheme* determines if a low prio or high prio job is selected
next. The default is `4, 1`, meaning to first select 4 high priority
jobs and then 1 low priority job, then starting over. If no such job
exists, its falls back to the other priority.

The priority can be set on a *Source* (see
[uploads](uploading.html)). Uploading through the web application will
always use priority *high*. The idea is that while logged in, jobs are
more important that those submitted when not logged in.


## Scheduler Config

The relevant part of the config file regarding the scheduler is shown
below with some explanations.

```
docspell.joex {
  # other settings left out for brevity

  scheduler {

    # Number of processing allowed in parallel.
    pool-size = 2

    # A counting scheme determines the ratio of how high- and low-prio
    # jobs are run. For example: 4,1 means run 4 high prio jobs, then
    # 1 low prio and then start over.
    counting-scheme = "4,1"

    # How often a failed job should be retried until it enters failed
    # state. If a job fails, it becomes "stuck" and will be retried
    # after a delay.
    retries = 5

    # The delay until the next try is performed for a failed job. This
    # delay is increased exponentially with the number of retries.
    retry-delay = "1 minute"

    # The queue size of log statements from a job.
    log-buffer-size = 500

    # If no job is left in the queue, the scheduler will wait until a
    # notify is requested (using the REST interface). To also retry
    # stuck jobs, it will notify itself periodically.
    wakeup-period = "30 minutes"
  }
}
```

The `pool-size` setting deterimens how many jobs run in parallel. You
need to play with this setting on your machine to find an optimal
value.

The `counting-scheme` determines for all collectives how to select
between high and low priority jobs; as explained above. It is
currently not possible to define that per collective.

If a job fails, it will be set to *stuck* state and retried by the
scheduler. The `retries` setting defines how many times a job is
retried until it enters the final *failed* state. The scheduler waits
some time until running the next try. This delay is given by
`retry-delay`. This is the initial delay, the time until the first
re-try (the second attempt). This time increases exponentially with
the number of retries.

The jobs will log about what they do, which is picked up and stored
into the database asynchronously. The log events are buffered in a
queue and another thread will consume this queue and store them in the
database. The `log-buffer-size` determines the size of the queue.

At last, there is a `wakeup-period` that determines at what interval
the joex component notifies itself to look for new jobs. If jobs get
stuck, and joex is not notified externally it could miss to
retry. Also, since networks are not reliable, a notification may not
reach a joex component. This periodic wakup is just to ensure that
jobs are eventually run.


## Starting on demand

The job executor and rest server can be started multiple times. This
is especially useful for the job executor. For example, when
submitting a lot of files in a short time, you can simply startup more
job executors on other computers on your network. Maybe use your
laptop to help with processing for a while.

You have to make sure, that all connect to the same database, and that
all have unique `app-id`s.

Once the files have been processced you can stop the additional
executors.

## Shutting down

If a job executor is sleeping and not executing any jobs, you can just
quit using SIGTERM or `Ctrl-C` when running in a terminal. But if
there are jobs currently executing, it is advisable to initiate a
graceful shutdown. The job executor will then stop taking new jobs
from the queue but it will wait until all running jobs have completed
before shutting down.

This can be done by sending a http POST request to the api of this job
executor:

```
curl -XPOST "http://localhost:7878/api/v1/shutdownAndExit"
```

If joex receives this request it will immediately stop taking new jobs
and it will quit when all running jobs are done.

If a job executor gets terminated while there are running jobs, the
jobs are still in the current state marked to be executed by this job
executor. In order to fix this, start the job executor again. It will
search all jobs that are marked with its id and put them back into
waiting state. Then send a graceful shutdown request as shown above.
