CREATE TABLE "useremail" (
  "id" varchar(254) not null primary key,
  "uid" varchar(254) not null,
  "name" varchar(254) not null,
  "smtp_host" varchar(254) not null,
  "smtp_port" int not null,
  "smtp_user" varchar(254) not null,
  "smtp_password" varchar(254) not null,
  "smtp_ssl" varchar(254) not null,
  "smtp_certcheck" boolean not null,
  "mail_from" varchar(254) not null,
  "mail_replyto" varchar(254),
  "created" timestamp not null,
  unique ("uid", "name"),
  foreign key ("uid") references "user_"("uid")
);
