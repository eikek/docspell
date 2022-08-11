drop index "ftspsql_search_ftsidx";
drop index "ftpsql_search_item_idx";
drop index "ftpsql_search_attach_idx";
drop index "ftpsql_search_folder_idx";
drop table "ftspsql_search" cascade;

create table "ftspsql_search"(
  "id" varchar(254) not null primary key,
  "item_id" varchar(254) not null,
  "collective" bigint not null,
  "lang" varchar(254) not null,
  "attach_id" varchar(254),
  "folder_id" varchar(254),
  "updated_at" timestamptz not null default current_timestamp,
  --- content columns
  "attach_name" text,
  "attach_content" text,
  "item_name" text,
  "item_notes" text,
  --- index column
  "fts_config" regconfig not null,
  "text_index" tsvector
    generated always as (
     setweight(to_tsvector("fts_config", coalesce("attach_name", '')), 'B') ||
     setweight(to_tsvector("fts_config", coalesce("item_name", '')), 'B') ||
     setweight(to_tsvector("fts_config", coalesce("attach_content", '')), 'C') ||
     setweight(to_tsvector("fts_config", coalesce("item_notes", '')), 'C')) stored
);

create index "ftspsql_search_ftsidx" on "ftspsql_search" using GIN ("text_index");
create index "ftpsql_search_item_idx" on "ftspsql_search"("item_id");
create index "ftpsql_search_attach_idx" on "ftspsql_search"("attach_id");
create index "ftpsql_search_folder_idx" on "ftspsql_search"("folder_id");
