# User Documentation

## Concepts


## UI Screens

The web application is the provided user interface. THere are the following screens


### Login

### Change Password

### Document Overview

- search menu on the left, 25%
- listing in the middle, 25%
  - choose to list all documents
  - or grouped by date, corresp. etc
- right: document preview + details, 50%

### Document Edit

- search menu + listing is replaced by edit screen, 50%
- document preview 50%

### Manage Additional Data

CRUD for

- Organisation
- Person
- Equipment
- Sources, which are the possible upload endpoints.

### Collective Settings

- keystore
- collective data
- manage users

### User Settings

- preferences (language, ...)
- smtp servers

### Super Settings

- admin only
- enable/disable registration
- settings for the app and collectives
  - e.g. can block collectives or users
- CRUD for all entities

### Collective Processing Queue

- user can inspect current processing
- see errors and progress
- see jobs in queue
- cancel jobs
- see some stats about executors, so one can make an educated guess as
  to when the next job is executed

### Admin Processing Queue

- see which external processing workers are registered
- cancel/pause jobs
- some stats
