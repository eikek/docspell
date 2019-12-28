CREATE TABLE "filemeta" (
  "id" varchar(254) not null primary key,
  "timestamp" varchar(40) not null,
  "mimetype" varchar(254) not null,
  "length" bigint not null,
  "checksum" varchar(254) not null,
  "chunks" int not null,
  "chunksize" int not null
);

CREATE TABLE "filechunk" (
  fileId varchar(254) not null,
  chunkNr int not null,
  chunkLength int not null,
  chunkData bytea not null,
  primary key (fileId, chunkNr)
);

CREATE TABLE "collective" (
  "cid" varchar(254) not null primary key,
  "state" varchar(254) not null,
  "doclang" varchar(254) not null,
  "created" timestamp not null
);

CREATE TABLE "user_" (
  "uid" varchar(254) not null primary key,
  "login" varchar(254) not null,
  "cid" varchar(254) not null,
  "password" varchar(254) not null,
  "state" varchar(254) not null,
  "email" varchar(254),
  "logincount" int not null,
  "lastlogin" timestamp,
  "created" timestamp not null,
  unique ("cid", "login"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "invitation" (
  "id" varchar(254) not null primary key,
  "created" timestamp not null
);

CREATE TABLE "source" (
  "sid" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "abbrev" varchar(254) not null,
  "description" text,
  "counter" int not null,
  "enabled" boolean not null,
  "priority" int not null,
  "created" timestamp not null,
  unique ("cid", "abbrev"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "organization" (
  "oid" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "name" varchar(254) not null,
  "street" varchar(254),
  "zip" varchar(254),
  "city" varchar(254),
  "country" varchar(254),
  "notes" text,
  "created" timestamp not null,
  unique ("cid", "name"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "person" (
  "pid" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "name" varchar(254) not null,
  "street" varchar(254),
  "zip" varchar(254),
  "city" varchar(254),
  "country" varchar(254),
  "notes" text,
  "concerning" boolean not null,
  "created" varchar(30) not null,
  unique ("cid", "name"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "contact" (
  "contactid" varchar(254) not null primary key,
  "value" varchar(254) not null,
  "kind" varchar(254) not null,
  "pid" varchar(254),
  "oid" varchar(254),
  "created" timestamp not null,
  foreign key ("pid") references "person"("pid"),
  foreign key ("oid") references "organization"("oid")
);

CREATE TABLE "equipment" (
  "eid" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "name" varchar(254) not null,
  "created" timestamp not null,
  unique ("cid","eid"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "item" (
  "itemid" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "name" varchar(254) not null,
  "itemdate" timestamp,
  "source" varchar(254) not null,
  "incoming" boolean not null,
  "state" varchar(254) not null,
  "corrorg" varchar(254),
  "corrperson" varchar(254),
  "concperson" varchar(254),
  "concequipment" varchar(254),
  "inreplyto" varchar(254),
  "duedate" timestamp,
  "notes" text,
  "created" timestamp not null,
  "updated" timestamp not null,
  foreign key ("inreplyto") references "item"("itemid"),
  foreign key ("corrorg") references "organization"("oid"),
  foreign key ("corrperson") references "person"("pid"),
  foreign key ("concperson") references "person"("pid"),
  foreign key ("concequipment") references "equipment"("eid"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "attachment" (
  "attachid" varchar(254) not null primary key,
  "itemid" varchar(254) not null,
  "filemetaid" varchar(254) not null,
  "position" int not null,
  "created" timestamp not null,
  "name" varchar(254),
  foreign key ("itemid") references "item"("itemid"),
  foreign key ("filemetaid") references "filemeta"("id")
);

CREATE TABLE "attachmentmeta" (
  "attachid" varchar(254) not null primary key,
  "content" text,
  "nerlabels" text,
  "itemproposals" text,
  foreign key ("attachid") references "attachment"("attachid")
);

CREATE TABLE "tag" (
  "tid" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "name" varchar(254) not null,
  "category" varchar(254),
  "created" timestamp not null,
  unique ("cid", "name"),
  foreign key ("cid") references "collective"("cid")
);

CREATE TABLE "tagitem" (
  "tagitemid" varchar(254) not null primary key,
  "itemid" varchar(254) not null,
  "tid" varchar(254) not null,
  unique ("itemid", "tid"),
  foreign key ("itemid") references "item"("itemid"),
  foreign key ("tid") references "tag"("tid")
);

CREATE TABLE "job" (
  "jid" varchar(254) not null primary key,
  "task" varchar(254) not null,
  "group_" varchar(254) not null,
  "args" text not null,
  "subject" varchar(254) not null,
  "submitted" timestamp not null,
  "submitter" varchar(254) not null,
  "priority" int not null,
  "state" varchar(254) not null,
  "retries" int not null,
  "progress" int not null,
  "tracker" varchar(254),
  "worker" varchar(254),
  "started" timestamp,
  "finished" timestamp,
  "startedmillis" bigint
);

CREATE TABLE "joblog" (
  "id" varchar(254) not null primary key,
  "jid" varchar(254) not null,
  "level" varchar(254) not null,
  "created" timestamp not null,
  "message" text not null,
  foreign key ("jid") references "job"("jid")
);

CREATE TABLE "jobgroupuse" (
  "groupid" varchar(254) not null,
  "workerid" varchar(254) not null,
  primary key ("groupid", "workerid")
);

CREATE TABLE "node" (
  "id" varchar(254) not null,
  "type" varchar(254) not null,
  "url" varchar(254) not null,
  "updated" timestamp not null,
  "created" timestamp not null
)
