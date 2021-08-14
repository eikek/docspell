CREATE TABLE "empty_trash_setting" (
  "cid" varchar(254) not null primary key,
  "schedule" varchar(254) not null,
  "created" timestamp not null,
  foreign key ("cid") references "collective"("cid")
);
