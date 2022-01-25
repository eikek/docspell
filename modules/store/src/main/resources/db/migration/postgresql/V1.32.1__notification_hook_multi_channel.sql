CREATE TABLE "notification_hook_channel" (
  "id" varchar(254) not null primary key,
  "hook_id" varchar(254) not null,
  "channel_mail" varchar(254),
  "channel_gotify" varchar(254),
  "channel_matrix" varchar(254),
  "channel_http" varchar(254),
  foreign key ("hook_id") references "notification_hook"("id") on delete cascade,
  foreign key ("channel_mail") references "notification_channel_mail"("id") on delete cascade,
  foreign key ("channel_gotify") references "notification_channel_gotify"("id") on delete cascade,
  foreign key ("channel_matrix") references "notification_channel_matrix"("id") on delete cascade,
  foreign key ("channel_http") references "notification_channel_http"("id") on delete cascade,
  unique("hook_id", "channel_mail"),
  unique("hook_id", "channel_gotify"),
  unique("hook_id", "channel_matrix"),
  unique("hook_id", "channel_http")
);

insert into "notification_hook_channel" ("id", "hook_id", "channel_mail", "channel_gotify", "channel_matrix", "channel_http")
select md5(random()::text), id, channel_mail, channel_gotify, channel_matrix, channel_http
from "notification_hook";

alter table "notification_hook"
drop column "channel_mail";

alter table "notification_hook"
drop column "channel_gotify";

alter table "notification_hook"
drop column "channel_matrix";

alter table "notification_hook"
drop column "channel_http";
