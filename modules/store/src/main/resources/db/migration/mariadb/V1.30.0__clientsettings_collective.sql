RENAME TABLE `client_settings` TO `client_settings_user`;

CREATE TABLE `client_settings` (
  `id` varchar(254) not null primary key,
  `cid` varchar(254) not null,
  `user_id` varchar(254) not null,
  `settings_data` longtext not null,
  `created` timestamp not null,
  `updated` timestamp not null,
  foreign key (`cid`) references `collective`(`cid`) on delete cascade,
  unique (`client_id`, `cid`)
);
