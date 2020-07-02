CREATE TABLE "space" (
  "id" varchar(254) not null primary key,
  "name" varchar(254) not null,
  "cid" varchar(254) not null,
  "owner" varchar(254) not null,
  "created" timestamp not null,
  unique ("name", "cid"),
  foreign key ("cid") references "collective"("cid"),
  foreign key ("owner") references "user_"("uid")
);

CREATE TABLE "space_member" (
  "id" varchar(254) not null primary key,
  "space_id" varchar(254) not null,
  "user_id" varchar(254) not null,
  "created" timestamp not null,
  unique ("space_id", "user_id"),
  foreign key ("space_id") references "space"("id"),
  foreign key ("user_id") references "user_"("uid")
);

ALTER TABLE "item"
ADD COLUMN "space_id" varchar(254) NULL;
