CREATE TABLE `client_settings` (
  `id` varchar(254) not null primary key,
  `client_id` varchar(254) not null,
  `user_id` varchar(254) not null,
  `settings_data` longtext not null,
  `created` timestamp not null,
  `updated` timestamp not null,
  foreign key (`user_id`) references `user_`(`uid`) on delete cascade,
  unique (`client_id`, `user_id`)
);
