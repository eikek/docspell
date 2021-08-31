CREATE TABLE `totp` (
  `user_id` varchar(254) not null primary key,
  `enabled` boolean not null,
  `secret` varchar(254) not null,
  `created` timestamp not null,
  FOREIGN KEY (`user_id`) REFERENCES `user_`(`uid`) ON DELETE CASCADE
);
