CREATE TABLE "item_proposal" (
  "itemid" varchar(254) not null primary key,
  "classifier_proposals" text not null,
  "classifier_tags" text not null,
  "created" timestamp not null,
  foreign key ("itemid") references "item"("itemid")
);
