drop table if exists file_migration_temp;
create table file_migration_temp (
  id bigserial primary key,
  original_file varchar(254) not null unique,
  cid varchar(254) not null,
  category varchar(254) not null,
  new_file varchar(254) not null unique
);

-- Source files
insert into file_migration_temp (original_file, cid, category, new_file)
  select
    rs.file_id as original_file,
    i.cid,
    'attachmentsource' as category,
    i.cid || '/attachmentsource/' || rs.file_id as new_file
  from attachment_source rs
  inner join attachment ra on rs.id = ra.attachid
  inner join item i on ra.itemid = i.itemid
;

-- Archive files
insert into file_migration_temp (original_file, cid, category, new_file)
  select distinct
    rs.file_id as original_file,
    i.cid,
    'attachmentsource' as category,
    i.cid || '/attachmentsource/' || rs.file_id as new_file
  from attachment_archive rs
  inner join attachment ra on rs.id = ra.attachid
  inner join item i on ra.itemid = i.itemid
;

-- Converted files
insert into file_migration_temp (original_file, cid, category, new_file)
  select
    ra.filemetaid as original_file,
    i.cid,
    'attachmentconvert' as category,
    i.cid || '/attachmentconvert/' || ra.filemetaid as new_file
  from attachment_source rs
  inner join attachment ra on rs.id = ra.attachid
  inner join item i on ra.itemid = i.itemid
  where rs.file_id <> ra.filemetaid
;

-- Preview image
insert into file_migration_temp (original_file, cid, category, new_file)
  select
    ap.file_id as original_file,
    i.cid,
    'previewimage' as category,
    i.cid || '/previewimage/' || ap.file_id as new_file
  from attachment_preview ap
  inner join attachment ra on ra.attachid = ap.id
  inner join item i on i.itemid = ra.itemid
  order by id
;

-- classifier
insert into file_migration_temp (original_file, cid, category, new_file)
  select
    file_id as original_file,
    cid,
    'classifier' as category,
    cid || '/classifier/' || file_id as new_file
  from classifier_model
;


-- save obsolete/orphaned files
drop table if exists obsolete_files;
create table obsolete_files(
  file_id varchar(254) not null,
  mimetype varchar(254) not null,
  length bigint not null,
  checksum varchar(254) not null,
  created timestamp not null
);

with
  missing_ids as (
    select file_id from filemeta
    except
    select original_file as file_id from file_migration_temp)
insert into obsolete_files (file_id, mimetype, length, checksum, created)
  select file_id, mimetype, length, checksum, created from filemeta
  where file_id in (select file_id from missing_ids)
;


-- duplicate each filemeta with the new id
insert into filemeta (file_id, mimetype, length, checksum, created)
  select mm.new_file, fm.mimetype, fm.length, fm.checksum, fm.created
  from file_migration_temp mm
  inner join filemeta fm on fm.file_id = mm.original_file
;


-- update each reference to the new id
update attachment_source
  set file_id = (select new_file
                 from file_migration_temp
                 where original_file = file_id and attachment_source.id is not null)
;

update attachment
  set filemetaid = (select new_file
                    from file_migration_temp
                    where original_file = filemetaid and attachment.attachid is not null)
;

update attachment_archive
  set file_id = (select new_file
                 from file_migration_temp
                 where original_file = file_id and attachment_archive.id is not null)
;

update attachment_preview
  set file_id = (select new_file
                 from file_migration_temp
                 where original_file = file_id and attachment_preview.id is not null)
;

update classifier_model
  set file_id = (select new_file
                 from file_migration_temp
                 where original_file = file_id and classifier_model.id is not null)
;

-- delete old filemeta and filechunk rows
delete from filemeta
where file_id in (select original_file from file_migration_temp);

delete from filemeta
where file_id in (select file_id from obsolete_files);

delete from filechunk
where file_id in (select file_id from obsolete_files);

-- update chunks
update filechunk
  set file_id = (select new_file
                 from file_migration_temp
                 where original_file = file_id and filechunk.file_id is not null)
;

-- drop temp table
drop table file_migration_temp;
drop table obsolete_files;
