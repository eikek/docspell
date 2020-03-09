CREATE TABLE `periodic_task` (
  `id` varchar(254) not null primary key,
  `enabled` boolean not null,
  `task` varchar(254) not null,
  `group_` varchar(254) not null,
  `args` text not null,
  `subject` varchar(254) not null,
  `submitter` varchar(254) not null,
  `priority` int not null,
  `worker` varchar(254),
  `marked` timestamp,
  `timer` varchar(254) not null,
  `nextrun` timestamp not null,
  `created` timestamp not null
);

CREATE INDEX `periodic_task_nextrun_idx` ON `periodic_task`(`nextrun`);
CREATE INDEX `periodic_task_worker_idx` ON `periodic_task`(`worker`);
