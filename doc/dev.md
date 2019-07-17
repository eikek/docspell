# Development Documentation


## initial thoughts

* First there is a web app, where user can login, look at their
  documents etc
* User can do queries and edit document meta data
* User can manage upload endpoints

Upload endpoints allow to receive "items". There are the following
different options:

1. Upload a single item by uploading one file.
2. Upload a single item by uploading a zip file.
3. Upload multiple items by uploading a zip file (one entry = one
   item)

Files are received and stored in the database, always. Only if a size
constraint is not fulfilled the response is an error. Files are marked
as `RECEIVED`. Idea is that most files are valid, so are saved
anyways.

Then a job for a new item is inserted into the processing queue and
processing begins eventually.

External processes access the queue on the same database and take jobs
for processing.

Processing:

1. check mimetype and error if not supported
   - want to use the servers mimetype instead of advertised one from
     the client
2. extract text and other meta data
3. do some analysis
4. tag item/set meta data
5. encrypt files + text, if configured

If an error occurs, it can be inspected in the "queue screen". The web
app shows notifications in this case. User can download the file and
remove it. Otherwise, files will be deleted after some period. Errors
are also counted per source, so one can decide whether to block a
source.

Once processing is done, the item is put in the INBOX.

## Modules

### processor

### backend

### store

### backend server

### webapp

## Flow


1. webapp: calls rest route
2. server:
   1. convert json -> data
   2. choose backend operation
3. backend: execute logic
   1. store: load or save from/to db
4. server:
   1. convert data -> json


backend:
- need better name
- contains all logic encoded as operations
- operation: A -> Either[E, B]
- middleware translates userId -> required data
  - e.g. userId -> public key
- operations can fail
  - common error class is used
  - can be converted to json easily


New Items:

1. upload endpoint
2. server:
   1. convert json->data
3. store: add job to queue
4. processor:
   1. eventually takes the job
   2. execute job
   3. notify about result


Processors

- multiple processors possible
- multiple backend servers possible
- separate processes
- register on database
  - unique id
  - url
  - servers and processors
- once a job is added to the queue notify all processors
  - take all registered urls from db
  - call them, skip failing ones
- processors wake up and take next job based on their config
- first free processor gets a new job
- once done, notify registered backend server
