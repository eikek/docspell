CREATE TABLE "userimap" (
  "id" varchar(254) not null primary key,
  "uid" varchar(254) not null,
  "name" varchar(254) not null,
  "imap_host" varchar(254) not null,
  "imap_port" int,
  "imap_user" varchar(254),
  "imap_password" varchar(254),
  "imap_ssl" varchar(254) not null,
  "imap_certcheck" boolean not null,
  "created" timestamp not null,
  unique ("uid", "name"),
  foreign key ("uid") references "user_"("uid")
);
