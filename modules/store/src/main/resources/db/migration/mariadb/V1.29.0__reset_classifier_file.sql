CREATE TEMPORARY TABLE `temp_file_ids` (
  cid varchar(254) not null,
  file_id varchar(254) not null
);

INSERT INTO `temp_file_ids` SELECT `cid`, `file_id` FROM `classifier_model`;

INSERT INTO `job`
       SELECT md5(rand()), 'learn-classifier', cid, CONCAT('{"collective":"', cid, '"}'),
              'new classifier', now(), 'docspell-system', 0, 'waiting', 0, 0,null,null,null,null,null
       FROM `classifier_setting`;

DELETE FROM `classifier_model`;

DELETE FROM `filemeta`
WHERE `file_id` in (SELECT `file_id` FROM `temp_file_ids`);

DELETE FROM `filechunk`
WHERE `file_id` in (SELECT `file_id` FROM `temp_file_ids`);

DROP TABLE `temp_file_ids`;
