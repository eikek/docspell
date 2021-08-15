ALTER TABLE `empty_trash_setting`
ADD COLUMN (`min_age` bigint);

UPDATE `empty_trash_setting`
SET `min_age` = 604800000;

ALTER TABLE `empty_trash_setting`
MODIFY `min_age` bigint NOT NULL;
