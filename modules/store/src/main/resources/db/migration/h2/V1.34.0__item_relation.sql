create table "item_link" (
  "id" varchar(254) not null primary key,
  "cid" varchar(254) not null,
  "item1" varchar(254) not null,
  "item2" varchar(254) not null,
  "created" timestamp not null,
  unique ("cid", "item1", "item2"),
  foreign key ("cid") references "collective"("cid") on delete cascade,
  foreign key ("item1") references "item"("itemid") on delete cascade,
  foreign key ("item2") references "item"("itemid") on delete cascade
);
