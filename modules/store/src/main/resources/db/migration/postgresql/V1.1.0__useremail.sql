CREATE TABLE "useremail" (
  "id" varchar(254) not null primary key,
  "uid" varchar(254) not null,
  "name" varchar(254) not null,
  "smtp_host" varchar(254) not null,
  "smtp_port" int,
  "smtp_user" varchar(254),
  "smtp_password" varchar(254),
  "smtp_ssl" varchar(254) not null,
  "smtp_certcheck" boolean not null,
  "mail_from" varchar(254) not null,
  "mail_replyto" varchar(254),
  "created" timestamp not null,
  unique ("uid", "name"),
  foreign key ("uid") references "user_"("uid")
);

CREATE TABLE "sentmail" (
  "id" varchar(254) not null primary key,
  "uid" varchar(254) not null,
  "item_id" varchar(254) not null,
  "message_id" varchar(254) not null,
  "sender" varchar(254) not null,
  "subject" varchar(254) not null,
  "recipients" varchar(254) not null,
  "body" text not null,
  "created" timestamp not null,
  foreign key("uid") references "user_"("uid"),
  foreign key("item_id") references "item"("itemid")
);
