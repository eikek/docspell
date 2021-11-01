CREATE TABLE "pubsub" (
  "id" varchar(254) not null primary key,
  "node_id" varchar(254) not null,
  "url" varchar(254) not null,
  "topic" varchar(254) not null,
  "counter" int not null,
  unique("url", "topic")
)
