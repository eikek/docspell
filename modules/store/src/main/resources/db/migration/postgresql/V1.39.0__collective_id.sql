-- add new id column
alter table "collective" add column "id" bigserial not null;
create unique index "collective_id_idx" on "collective"("id");

-- change references: source
alter table "source" add column "coll_id" bigint not null default 0;
update "source" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "source_coll_id_idx" on "source"("coll_id");
alter table "source" add constraint "source_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "source" drop constraint "source_cid_fkey";
alter table "source" drop column "cid";
alter table "source" alter column "coll_id" drop default;

-- change references: tag
alter table "tag" add column "coll_id" bigint not null default 0;
update "tag" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "tag_coll_id_idx" on "tag"("coll_id");
create unique index "tag_coll_id_name_idx" on "tag"("coll_id", "name");
alter table "tag" add constraint "tag_coll_id_name_key" unique using index "tag_coll_id_name_idx";
alter table "tag" add constraint "tag_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "tag" drop constraint "tag_cid_fkey";
alter table "tag" drop column "cid";
alter table "tag" alter column "coll_id" drop default;

-- change references: user_
alter table "user_" add column "coll_id" bigint not null default 0;
update "user_" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "user__coll_id_idx" on "user_"("coll_id");
create unique index "user__coll_id_login_idx" on "user_"("coll_id", "login");
alter table "user_" add constraint "user__coll_id_login_key" unique using index "user__coll_id_login_idx";
alter table "user_" add constraint "user__coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "user_" drop constraint if exists "user__cid_fkey";
alter table "user_" drop constraint if exists "user_cid_fkey";
alter table "user_" drop column "cid";
alter table "user_" alter column "coll_id" drop default;

-- change references: query_bookmark
alter table "query_bookmark" add column "coll_id" bigint not null default 0;
update "query_bookmark" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "query_bookmark_coll_id_idx" on "query_bookmark"("coll_id");
create unique index "query_bookmark_coll_id__user_id_name_idx" on "query_bookmark"("coll_id", "__user_id", "name");
alter table "query_bookmark" add constraint "query_bookmark_coll_id__user_id_name_key" unique using index "query_bookmark_coll_id__user_id_name_idx";
alter table "query_bookmark" add constraint "query_bookmark_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "query_bookmark" drop constraint "query_bookmark_cid_fkey";
alter table "query_bookmark" drop column "cid";
alter table "query_bookmark" alter column "coll_id" drop default;

-- change references: person
alter table "person" add column "coll_id" bigint not null default 0;
update "person" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "person_coll_id_idx" on "person"("coll_id");
create unique index "person_coll_id_name_idx" on "person"("coll_id", "name");
alter table "person" add constraint "person_coll_id_name_key" unique using index "person_coll_id_name_idx";
alter table "person" add constraint "person_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "person" drop constraint "person_cid_fkey";
alter table "person" drop column "cid";
alter table "person" alter column "coll_id" drop default;

-- change references: organization
alter table "organization" add column "coll_id" bigint not null default 0;
update "organization" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "organization_coll_id_idx" on "organization"("coll_id");
create unique index "organization_coll_id_name_idx" on "organization"("coll_id", "name");
alter table "organization" add constraint "organization_coll_id_name_key" unique using index "organization_coll_id_name_idx";
alter table "organization" add constraint "organization_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "organization" drop constraint "organization_cid_fkey";
alter table "organization" drop column "cid";
alter table "organization" alter column "coll_id" drop default;

-- change references: item_link
alter table "item_link" add column "coll_id" bigint not null default 0;
update "item_link" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "item_link_coll_id_idx" on "item_link"("coll_id");
create unique index "item_link_coll_id_item1_item2_idx" on "item_link"("coll_id", "item1", "item2");
alter table "item_link" add constraint "item_link_coll_id_item1_item2_key" unique using index "item_link_coll_id_item1_item2_idx";
alter table "item_link" add constraint "item_link_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "item_link" drop constraint "item_link_cid_fkey";
alter table "item_link" drop column "cid";
alter table "item_link" alter column "coll_id" drop default;

-- change references: item
alter table "item" add column "coll_id" bigint not null default 0;
update "item" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "item_coll_id_idx" on "item"("coll_id");
alter table "item" add constraint "item_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "item" drop constraint "item_cid_fkey";
alter table "item" drop column "cid";
alter table "item" alter column "coll_id" drop default;

-- change references: folder
alter table "folder" add column "coll_id" bigint not null default 0;
update "folder" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "folder_coll_id_idx" on "folder"("coll_id");
create unique index "folder_coll_id_name_idx" on "folder"("coll_id", "name");
alter table "folder" add constraint "folder_coll_id_name_key" unique using index "folder_coll_id_name_idx";
alter table "folder" add constraint "folder_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "folder" drop constraint "folder_cid_fkey";
alter table "folder" drop column "cid";
alter table "folder" alter column "coll_id" drop default;

-- change references: equipment
alter table "equipment" add column "coll_id" bigint not null default 0;
update "equipment" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "equipment_coll_id_idx" on "equipment"("coll_id");
create unique index "equipment_coll_id_name_idx" on "equipment"("coll_id", "name");
alter table "equipment" add constraint "equipment_coll_id_name_key" unique using index "equipment_coll_id_name_idx";
alter table "equipment" add constraint "equipment_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "equipment" drop constraint "equipment_cid_fkey";
alter table "equipment" drop constraint "equipment_cid_eid_key";
alter table "equipment" drop column "cid";
alter table "equipment" alter column "coll_id" drop default;

-- change references: empty_trash_setting
alter table "empty_trash_setting" add column "coll_id" bigint not null default 0;
update "empty_trash_setting" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "empty_trash_setting_coll_id_idx" on "empty_trash_setting"("coll_id");
alter table "empty_trash_setting" add constraint "empty_trash_setting_coll_id_fkey"
foreign key ("coll_id") references "collective"("id");
alter table "empty_trash_setting" drop constraint "empty_trash_setting_cid_fkey";
alter table "empty_trash_setting" drop column "cid";
alter table "empty_trash_setting" alter column "coll_id" drop default;
alter table "empty_trash_setting" add primary key(coll_id);

-- change references: download_query
alter table "download_query" add column "coll_id" bigint not null default 0;
update "download_query" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "download_query_coll_id_idx" on "download_query"("coll_id");
alter table "download_query" add constraint "download_query_coll_id_fkey"
foreign key ("coll_id") references "collective"("id");
alter table "download_query" drop constraint "download_query_cid_fkey";
alter table "download_query" drop column "cid";
alter table "download_query" alter column "coll_id" drop default;

-- change references: custom_field
alter table "custom_field" add column "coll_id" bigint not null default 0;
update "custom_field" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "custom_field_coll_id_idx" on "custom_field"("coll_id");
create unique index "custom_field_coll_id_name_idx" on "custom_field"("coll_id", "name");
alter table "custom_field" add constraint "custom_field_coll_id_name_key" unique using index "custom_field_coll_id_name_idx";
alter table "custom_field" add constraint "custom_field_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "custom_field" drop constraint "custom_field_cid_fkey";
alter table "custom_field" drop column "cid";
alter table "custom_field" alter column "coll_id" drop default;

-- change references: collective_password
alter table "collective_password" add column "coll_id" bigint not null default 0;
update "collective_password" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "collective_password_coll_id_idx" on "collective_password"("coll_id");
alter table "collective_password" add constraint "collective_password_coll_id_fkey"
foreign key ("coll_id") references "collective"("id");
alter table "collective_password" drop constraint "collective_password_cid_fkey";
alter table "collective_password" drop column "cid";
alter table "collective_password" alter column "coll_id" drop default;

-- change references: client_settings_collective
alter table "client_settings_collective" add column "coll_id" bigint not null default 0;
update "client_settings_collective" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "client_settings_collective_coll_id_idx" on "client_settings_collective"("coll_id");
create unique index "client_settings_collective_coll_id_client_id_idx" on "client_settings_collective"("coll_id", "client_id");
alter table "client_settings_collective" add constraint "client_settings_collective_coll_id_name_key" unique using index "client_settings_collective_coll_id_client_id_idx";
alter table "client_settings_collective" add constraint "client_settings_collective_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "client_settings_collective" drop constraint "client_settings_collective_cid_fkey";
alter table "client_settings_collective" drop column "cid";
alter table "client_settings_collective" alter column "coll_id" drop default;

-- change references: classifier_setting
alter table "classifier_setting" add column "coll_id" bigint not null default 0;
update "classifier_setting" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "classifier_setting_coll_id_idx" on "classifier_setting"("coll_id");
alter table "classifier_setting" add constraint "classifier_setting_coll_id_fkey"
 foreign key ("coll_id") references "collective"("id");
alter table "classifier_setting" drop constraint "classifier_setting_cid_fkey";
alter table "classifier_setting" drop column "cid";
alter table "classifier_setting" alter column "coll_id" drop default;

-- change references: classifier_model
alter table "classifier_model" add column "coll_id" bigint not null default 0;
update "classifier_model" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "classifier_model_coll_id_idx" on "classifier_model"("coll_id");
create unique index "classifier_model_coll_id_name_idx" on "classifier_model"("coll_id", "name");
alter table "classifier_model" add constraint "classifier_model_coll_id_name_key" unique using index "classifier_model_coll_id_name_idx";
alter table "classifier_model" add constraint "classifier_model_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "classifier_model" drop constraint "classifier_model_cid_fkey";
alter table "classifier_model" drop column "cid";
alter table "classifier_model" alter column "coll_id" drop default;

-- change references: addon_run_config
alter table "addon_run_config" add column "coll_id" bigint not null default 0;
update "addon_run_config" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "addon_run_config_coll_id_idx" on "addon_run_config"("coll_id");
alter table "addon_run_config" add constraint "addon_run_config_coll_id_fkey"
 foreign key ("coll_id") references "collective"("id");
alter table "addon_run_config" drop constraint "addon_run_config_cid_fkey";
alter table "addon_run_config" drop column "cid";
alter table "addon_run_config" alter column "coll_id" drop default;

-- change references: addon_archive
alter table "addon_archive" add column "coll_id" bigint not null default 0;
update "addon_archive" t set "coll_id" = (select id from collective where "cid" = t."cid");
create index "addon_archive_coll_id_idx" on "addon_archive"("coll_id");
create unique index "addon_archive_coll_id_name_version_idx" on "addon_archive"("coll_id", "name", "version");
create unique index "addon_archive_coll_id_original_url_idx" on "addon_archive"("coll_id", "original_url");
alter table "addon_archive" add constraint "addon_archive_coll_id_name_version_key" unique using index "addon_archive_coll_id_name_version_idx";
alter table "addon_archive" add constraint "addon_archive_coll_id_original_url_key" unique using index "addon_archive_coll_id_original_url_idx";
alter table "addon_archive" add constraint "addon_archive_coll_id_fkey" foreign key ("coll_id") references "collective"("id");
alter table "addon_archive" drop constraint "addon_archive_cid_fkey";
alter table "addon_archive" drop column "cid";
alter table "addon_archive" alter column "coll_id" drop default;


-- change primary key
alter table "collective" drop constraint "collective_pkey";
alter table "collective" add constraint "collective_id_pkey" primary key ("id");
alter table "collective" rename column "cid" to "name";
create unique index "collective_name_idx" on "collective"("name");
alter table "collective" add constraint "collective_name_key" unique using index "collective_name_idx";
