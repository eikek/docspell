CREATE TABLE `query_bookmark` (
  `id` varchar(254) not null primary key,
  `name` varchar(254) not null,
  `label` varchar(254),
  `user_id` varchar(254),
  `cid` varchar(254) not null,
  `query` varchar(2000) not null,
  `created` timestamp,
  foreign key (`user_id`) references `user_`(`uid`) on delete cascade,
  foreign key (`cid`) references `collective`(`cid`) on delete cascade,
  unique(`cid`, `user_id`, `name`)
)
