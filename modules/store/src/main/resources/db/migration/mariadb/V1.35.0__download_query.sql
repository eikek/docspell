CREATE TABLE `download_query`(
  `id` varchar(254) not null primary key,
  `cid` varchar(254) not null,
  `file_id` varchar(254) not null,
  `file_count` int not null,
  `created` timestamp not null,
  `last_access` timestamp,
  `access_count` int not null,
  foreign key (`cid`) references `collective`(`cid`),
  foreign key (`file_id`) references `filemeta`(`file_id`)
);
