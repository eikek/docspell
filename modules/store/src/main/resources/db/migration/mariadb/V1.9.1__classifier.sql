CREATE TABLE `classifier_setting` (
  `cid` varchar(254) not null primary key,
  `enabled` boolean not null,
  `schedule` varchar(254) not null,
  `category` varchar(254) not null,
  `item_count` int not null,
  `file_id` varchar(254),
  `created` timestamp not null,
  foreign key (`cid`) references `collective`(`cid`),
  foreign key (`file_id`) references `filemeta`(`id`)
);
