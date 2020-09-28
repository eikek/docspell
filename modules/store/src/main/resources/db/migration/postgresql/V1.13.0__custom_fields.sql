CREATE TABLE "custom_field" (
  "id" varchar(254) not null primary key,
  "name" varchar(254) not null,
  "cid" varchar(254) not null,
  "ftype" varchar(100) not null,
  "created" timestamp not null,
  foreign key ("cid") references "collective"("cid"),
  unique ("cid", "name")
);

CREATE TABLE "custom_field_value" (
  "id" varchar(254) not null primary key,
  "item_id" varchar(254) not null,
  "field" varchar(254) not null,
  "value_text" varchar(300),
  "value_numeric" numeric,
  foreign key ("item_id") references "item"("itemid"),
  foreign key ("field") references "custom_field"("id"),
  unique ("item_id", "field")
)
