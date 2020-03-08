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
  "timer" varchar(254) not null,
  "nextrun" timestamp not null
);
