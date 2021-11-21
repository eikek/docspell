create table `notification_channel_mail` (
  `id` varchar(254) not null primary key,
  `uid` varchar(254) not null,
  `conn_id` varchar(254) not null,
  `recipients` varchar(254) not null,
  `created` timestamp not null,
  foreign key (`uid`) references `user_`(`uid`) on delete cascade,
  foreign key (`conn_id`) references `useremail`(`id`) on delete cascade
);

create table `notification_channel_gotify` (
  `id` varchar(254) not null primary key,
  `uid` varchar(254) not null,
  `url` varchar(254) not null,
  `app_key` varchar(254) not null,
  `created` timestamp not null,
  foreign key (`uid`) references `user_`(`uid`) on delete cascade
);

create table `notification_channel_matrix` (
  `id` varchar(254) not null primary key,
  `uid` varchar(254) not null,
  `home_server` varchar(254) not null,
  `room_id` varchar(254) not null,
  `access_token` text not null,
  `message_type` varchar(254) not null,
  `created` timestamp not null,
  foreign key (`uid`) references `user_`(`uid`) on delete cascade
);

create table `notification_channel_http` (
  `id` varchar(254) not null primary key,
  `uid` varchar(254) not null,
  `url` varchar(254) not null,
  `created` timestamp not null,
  foreign key (`uid`) references `user_`(`uid`) on delete cascade
);

create table `notification_hook` (
  `id` varchar(254) not null primary key,
  `uid` varchar(254) not null,
  `enabled` boolean not null,
  `channel_mail` varchar(254),
  `channel_gotify` varchar(254),
  `channel_matrix` varchar(254),
  `channel_http` varchar(254),
  `all_events` boolean not null,
  `event_filter` varchar(500),
  `created` timestamp not null,
  foreign key (`uid`) references `user_`(`uid`) on delete cascade,
  foreign key (`channel_mail`) references `notification_channel_mail`(`id`) on delete cascade,
  foreign key (`channel_gotify`) references `notification_channel_gotify`(`id`) on delete cascade,
  foreign key (`channel_matrix`) references `notification_channel_matrix`(`id`) on delete cascade,
  foreign key (`channel_http`) references `notification_channel_http`(`id`) on delete cascade
);

create table `notification_hook_event` (
  `id` varchar(254) not null primary key,
  `hook_id` varchar(254) not null,
  `event_type` varchar(254) not null,
  foreign key (`hook_id`) references `notification_hook`(`id`) on delete cascade
);
