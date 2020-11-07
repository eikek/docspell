CREATE TABLE `attachment_preview` (
  `id` varchar(254) not null primary key,
  `file_id` varchar(254) not null,
  `filename` varchar(254),
  `created` timestamp not null,
  foreign key (`file_id`) references `filemeta`(`id`),
  foreign key (`id`) references `attachment`(`attachid`)
);
