# Component Interaction

## Context and Problem Statement

There are multiple web applications with their rest servers and there
are multiple document processors. These processes must communicate:

- once a new job is added to the queue the rest server must somehow
  notify processors to wake up
- once a processor takes a job, it must propagate the progress and
  outcome to all rest servers only that the rest server can notify the
  user that is currently logged in. Since it's not known which
  rest-server the user is using right now, all must be notified.

## Considered Options

1. JMS: Message Broker as another active component
2. Akka: using a cluster
3. DB: Register with "call back urls"

## Decision Outcome

Choosing option 3: DB as central synchronisation point.

The reason is that this is the simplest solution and doesn't require
external libraries or more processes. The other options seem too big
of a weapon for the task at hand.

It works roughly like this:

- rest servers and processors register at the database on startup each
  with a unique call-back url
- and deregister on shutdown
- each component has db access
- rest servers can list all processors and vice versa

### Positive Consequences

- complexity of the whole application is not touched
- since a lot of data must be transferred to the document processors,
  this is solved by simply accessing the db. So the protocol for data
  exchange is set. There is no need for other protocols that handle
  large data (http chunking etc)
- uses the already exsting db as synchronisation point
- no additional knowledge required
- simple to understand and so not hard to debug

### Negative Consequences

- all components must have db access. this also is a negative point,
  because if one of those processes is hacked, db access is
  possible. and it simply is another dependency that may not be
  required for the document processors
- the document processors cannot be in a untrusted environment
  (untrusted from the db's point of view). it would be for example
  possible to create personal processors that only receive your own
  jobs…
- in order to know if a component is really active, one must run a
  ping against the call-back url

## Pros and Cons of the Options

### JMS Message Broker

- pro: offers publish-subscribe out of the box
- con: another central point of failure
- con: requires setup and maintenance
- con: complexity of whole app is strongly increased, there are now at
  least 3 processes

### Akka Cluster

- pro: publish subscribe
- pro: no central component or separate process
- con: only works reliably in a "real cluster", where 3 nodes is a
  minimum. Thus it wouldn't allow a light-weight setup of the
  application
- con: introduces a new technology that is not easy to understand and
  maintain (the cluster, gossip protocol etc) requires to be "good at
  akka"

### DB Sync

- pro: simple and intuitive
- pro: no one more central point of failure
- pro: requires no additional knowledge or setup
- cons: all components require db access
