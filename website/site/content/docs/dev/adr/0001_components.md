+++
title = "Components"
weight = 20
+++

# Context and Problem Statement

How should the application be structured into its main components? The
goal is to be able to have multiple rest servers/webapps and multiple
document processor components working togehter.


# Decision Outcome

The following are the "main" modules. There may be more helper modules
and libraries that support implementing a feature.

## store

The code related to database access. It also provides the job
queue. It is designed as a library.

## joex

Joex stands for "job executor".

An application that executes jobs from the queue and therefore depends
on the `store` module. It provides the code for all tasks that can be
submitted as jobs. If no jobs are in the queue, the joex "sleeps"
and must be waked via an external request.

It provides the document processing code.

It provides a http rest server to get insight into the joex state
and also to be notified for new jobs.

## backend

It provides all the logic, except document processing, as a set of
"operations". An operation can be directly mapped to a rest
endpoint.

It is designed as a library.

## rest api

This module contains the specification for the rest server as an
`openapi.yml` file. It is packaged as a scala library that also
provides types and conversions to/from json.

The idea is that the `rest server` module can depend on it as well as
rest clients.

## rest server

This is the main application. It directly depends on the `backend`
module, and each rest endpoint maps to a "backend operation". It is
also responsible for converting the json data inside http requests
to/from types recognized by the `backend` module.


## webapp

This module provides the user interface as a web application.
