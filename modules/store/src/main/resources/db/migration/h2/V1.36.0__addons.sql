create table "addon_archive"(
  "id" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "file_id" varchar(254) not null,
  "original_url" varchar(2000),
  "name" varchar(254) not null,
  "version" varchar(254) not null,
  "description" text,
  "triggers" text not null,
  "created" timestamp not null,
  foreign key ("cid") references "collective"("cid"),
  foreign key ("file_id") references "filemeta"("file_id"),
  unique ("cid", "original_url"),
  unique ("cid", "name", "version")
);

create table "addon_run_config"(
  "id" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "user_id" varchar(254),
  "name" varchar(254) not null,
  "enabled" boolean not null,
  "created" timestamp not null,
  foreign key ("cid") references "collective"("cid"),
  foreign key ("user_id") references "user_"("uid")
);

create table "addon_run_config_addon" (
  "id" varchar(254) not null primary key,
  "addon_run_config_id" varchar(254) not null,
  "addon_id" varchar(254) not null,
  "args" text not null,
  "position" int not null,
  foreign key ("addon_run_config_id") references "addon_run_config"("id") on delete cascade,
  foreign key ("addon_id") references "addon_archive"("id") on delete cascade
);

create table "addon_run_config_trigger"(
  "id" varchar(254) not null primary key,
  "addon_run_config_id" varchar(254) not null,
  "triggers" varchar(254) not null,
  foreign key ("addon_run_config_id") references "addon_run_config"("id") on delete cascade,
  unique ("addon_run_config_id", "triggers")
);

alter table "node"
add column "server_secret" varchar;
