ALTER TABLE `source`
ADD COLUMN `file_filter` varchar(254) NULL;

CREATE TABLE `tagsource` (
  `id` varchar(254) not null primary key,
  `source_id` varchar(254) not null,
  `tag_id` varchar(254) not null,
  unique (`source_id`, `tag_id`),
  foreign key (`source_id`) references `source`(`sid`),
  foreign key (`tag_id`) references `tag`(`tid`)
);
