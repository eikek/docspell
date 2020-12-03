CREATE TABLE "rememberme" (
  "id" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "login" varchar(254) not null,
  "created" timestamp not null,
  "uses" int not null,
  FOREIGN KEY ("cid","login") REFERENCES "user_"("cid","login")
);
