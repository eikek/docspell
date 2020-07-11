CREATE TABLE "folder" (
  "id" varchar(254) not null primary key,
  "name" varchar(254) not null,
  "cid" varchar(254) not null,
  "owner" varchar(254) not null,
  "created" timestamp not null,
  unique ("name", "cid"),
  foreign key ("cid") references "collective"("cid"),
  foreign key ("owner") references "user_"("uid")
);

CREATE TABLE "folder_member" (
  "id" varchar(254) not null primary key,
  "folder_id" varchar(254) not null,
  "user_id" varchar(254) not null,
  "created" timestamp not null,
  unique ("folder_id", "user_id"),
  foreign key ("folder_id") references "folder"("id"),
  foreign key ("user_id") references "user_"("uid")
);

ALTER TABLE "item"
ADD COLUMN "folder_id" varchar(254) NULL;
