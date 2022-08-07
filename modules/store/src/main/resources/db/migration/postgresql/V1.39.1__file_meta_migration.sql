-- drop constraints to be able to update file ids
alter table "addon_archive" drop constraint "addon_archive_file_id_fkey";
alter table "attachment_archive" drop constraint "attachment_archive_file_id_fkey";
alter table "attachment" drop constraint "attachment_filemetaid_fkey";
alter table "attachment_source" drop constraint "attachment_source_file_id_fkey";
alter table "classifier_model" drop constraint "classifier_model_file_id_fkey";
alter table "download_query" drop constraint "download_query_file_id_fkey";
alter table "attachment_preview" drop constraint "attachment_preview_file_id_fkey";

-- create temporary tables holding old and new ids
create table "temp_prefixes"(
  old_prefix varchar(255) not null primary key,
  new_prefix varchar(255) not null
);
insert into "temp_prefixes"
select concat(name, '/'), concat(id, '/') from collective;

create table "temp_file_ids"(
  old_id varchar(255) not null primary key,
  old_prefix varchar(255) not null,
  new_prefix varchar(255) not null,
  new_id varchar(255) not null
);

with ids_orig(old_id, prefix) as
  (select file_id, concat(substring(file_id, 0, position('/' in file_id)), '/')
   from filemeta fm
  )
insert into "temp_file_ids"
select fm.old_id, tp.old_prefix, tp.new_prefix, replace(fm.old_id, tp.old_prefix, tp.new_prefix) as new_id
from ids_orig fm
inner join "temp_prefixes" tp on fm.prefix = tp.old_prefix;

-- remove orphaned files and chunks
delete from filemeta
where "file_id" not in (select "old_id" from "temp_file_ids");

delete from filechunk
where "file_id" not in (select "old_id" from "temp_file_ids");


-- update all references
update "filemeta" fm set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = fm."file_id");

update "addon_archive" aa set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = aa."file_id");

update "attachment_archive" aa set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = aa."file_id");

update "attachment" a set "filemetaid" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = a."filemetaid");

update "attachment_source" a set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = a."file_id");

update "classifier_model" cm set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = cm."file_id");

update "download_query" dq set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = dq."file_id");

update "attachment_preview" ap set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = ap."file_id");

-- update filechunks
update "filechunk" fc set "file_id" =
  (select t.new_id from "temp_file_ids" t where t."old_id" = fc."file_id");

-- re-create the constraints
alter table "addon_archive" add constraint "addon_archive_file_id_fkey"
foreign key ("file_id") references "filemeta"("file_id");

alter table "attachment_archive" add constraint "attachment_archive_file_id_fkey"
foreign key ("file_id") references "filemeta"("file_id");

alter table "attachment" add constraint "attachment_filemetaid_fkey"
foreign key ("filemetaid") references "filemeta"("file_id");

alter table "attachment_source" add constraint "attachment_source_file_id_fkey"
foreign key ("file_id") references "filemeta"("file_id");

alter table "classifier_model" add constraint "classifier_model_file_id_fkey"
foreign key ("file_id") references "filemeta"("file_id");

alter table "download_query" add constraint "download_query_file_id_fkey"
foreign key ("file_id") references "filemeta"("file_id");

alter table "attachment_preview" add constraint "attachment_preview_file_id_fkey"
foreign key ("file_id") references "filemeta"("file_id");

-- drop temporary tables
drop table "temp_file_ids";
drop table "temp_prefixes";
