ALTER TABLE "client_settings" RENAME TO "client_settings_user";

CREATE TABLE "client_settings_collective" (
  "id" varchar(254) not null primary key,
  "client_id" varchar(254) not null,
  "cid" varchar(254) not null,
  "settings_data" text not null,
  "created" timestamp not null,
  "updated" timestamp not null,
  foreign key ("cid") references "collective"("cid") on delete cascade,
  unique ("client_id", "cid")
);
