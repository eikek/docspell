alter table "rememberme" add column "user_id" varchar(254);

update "rememberme" m
set "user_id" = (select "uid" from "user_" where "login" = m."login" and "cid" = m."cid");

alter table "rememberme" alter column "user_id" set not null;

alter table "rememberme" drop constraint "CONSTRAINT_20F";
drop index "rememberme_cid_login_idx";
alter table "rememberme" drop column "login";
alter table "rememberme" drop column "cid";

create index "rememberme_user_id_idx" on "rememberme"("user_id");
alter table "rememberme" add constraint "remember_user_id_fk" foreign key("user_id") references "user_"("uid");
