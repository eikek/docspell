alter table "notification_channel_mail"
add column "name" varchar(254);

alter table "notification_channel_gotify"
add column "name" varchar(254);

alter table "notification_channel_matrix"
add column "name" varchar(254);

alter table "notification_channel_http"
add column "name" varchar(254);
