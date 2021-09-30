CREATE TABLE `collective_password` (
  `id` varchar(254) not null primary key,
  `cid` varchar(254) not null,
  `pass` varchar(254) not null,
  `created` timestamp not null,
  foreign key (`cid`) references `collective`(`cid`) on delete cascade
)
