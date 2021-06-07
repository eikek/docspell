+++
title = "Processing Queue"
weight = 80
[extra]
mktoc = true
+++


The page *Processing Queue* shows the current state of document
processing for your uploads. The page currently only shows at most the
80 newest jobs. There is a maximum of 40 done jobs (successful,
cancelled or failed) and 40 not done jobs.

The sidebar lets you filter for a specific job state. The *Currently
Running* tab shows all jobs that are currently executing and their log
output. The page refreshes automatically to show the progress.

Example screenshot:

{{ figure(file="processing-queue.png") }}

You can cancel running jobs or remove waiting ones from the queue. If
you click on the small file symbol on finished jobs, you can inspect
its log messages again. A running job displays the job executor id
that executes the job.

The jobs listed here are all long-running tasks for your collective.
Most of the time it executes the document processing tasks. But user
defined tasks, like "import mailbox", are also visible here.

Since job executors are shared among all collectives, it may happen
that a job is some time waiting until it is picked up by a job
executor. You can always start more job executors to help out.

If a job fails it first enters "stuck" state and is retried after some
time. Only if it fails too often (can be configured), it then is
finished with *failed* state.

For the document-processing task, if processing finally fails or a job
is cancelled, the item is still created, just without suggestions.
