CREATE TABLE `item_proposal` (
  `itemid` varchar(254) not null primary key,
  `classifier_proposals` mediumtext not null,
  `classifier_tags` mediumtext not null,
  `created` timestamp not null,
  foreign key (`itemid`) references `item`(`itemid`)
);
