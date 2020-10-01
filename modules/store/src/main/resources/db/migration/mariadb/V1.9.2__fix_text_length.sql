ALTER TABLE `attachmentmeta`
MODIFY COLUMN `content` longtext;

ALTER TABLE `attachmentmeta`
MODIFY COLUMN `nerlabels` longtext;

ALTER TABLE `attachmentmeta`
MODIFY COLUMN `itemproposals` longtext;

ALTER TABLE `job`
MODIFY COLUMN `args` mediumtext;

ALTER TABLE `joblog`
MODIFY COLUMN `message` mediumtext;
