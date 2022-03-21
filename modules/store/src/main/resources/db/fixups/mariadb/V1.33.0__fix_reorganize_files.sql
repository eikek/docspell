drop table if exists valid_file_ids;
create table valid_file_ids (
  id bigint auto_increment primary key,
  file_id varchar(254) not null unique
);

-- Source files
insert into valid_file_ids (file_id)
  select rs.file_id
  from attachment_source rs
;

-- Archive files
insert into valid_file_ids (file_id)
  select distinct rs.file_id
  from attachment_archive rs
;

-- Preview image
insert into valid_file_ids (file_id)
  select ap.file_id
  from attachment_preview ap
;

-- classifier
insert into valid_file_ids (file_id)
  select file_id
  from classifier_model
;

-- save obsolete files
drop table if exists obsolete_files;
create table obsolete_files(
  file_id varchar(254) not null
);

insert into obsolete_files (file_id)
  select file_id from filemeta
  where file_id in (
    select file_id from filemeta
    except
    select file_id as file_id from valid_file_ids
  );

-- remove orphaned chunks
delete from filechunk
where file_id in (
  select distinct file_id from filechunk
  where file_id not in (select file_id from valid_file_ids)
  and file_id not in (select file_id from obsolete_files)
);

-- drop temp table
drop table valid_file_ids;
drop table obsolete_files;
