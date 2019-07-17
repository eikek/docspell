# Components

## Context and Problem Statement

How should the application be structured into its main components? The
goal is to be able to have multiple rest servers/webapps and multiple
document processor components working togehter.


## Considered Options


## Decision Outcome

The following are the "main" modules. There may be more helper modules
and libraries that support implementing a feature.

### store

The code related to database access. It also provides the job
queue. It is designed as a library.

### joex

Joex stands for "job executor".

An application that executes jobs from the queue and therefore depends
on the `store` module. It provides the code for all tasks that can be
submitted as jobs. If no jobs are in the queue, the joex "sleeps"
and must be waked via an external request.

The main reason for this module is to provide the document processing
code.

It provides a http rest server to get insight into the joex state
and also to be notified for new jobs.

### backend

This is the heart of the application. It provides all the logic,
except document processing, as a set of "operations". An operation can
be directly mapped to a rest endpoint. An operation is roughly this:

```
A -> F[Either[E, B]]
```

First, it can fail and so there is some sort of either type to encode
failure. It also is inside a `F` context, since it may run impure
code, e.g. database calls. The input value `A` can be obtained by
amending the user input from a rest call with additional data from the
database corresponding to the current user (for example the public key
or some preference setting).

It is designed as a library.

### rest spec

This module contains the specification for the rest server as an
`openapi.yml` file. It is packaged as a scala library that also
provides types and conversions to/from json.

The idea is that the `rest server` module can depend on it as well as
rest clients.

### rest server

This is the main application. It directly depends on the `backend`
module, and each rest endpoint maps to a "backend operation". It is
also responsible for converting the json data inside http requests
to/from types recognized by the `backend` module.


### webapp

This module provides the user interface as a web application.
