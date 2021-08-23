ALTER TABLE `source`
ADD COLUMN (`attachments_only` BOOLEAN);

UPDATE `source`
SET  `attachments_only` = false;

ALTER TABLE `source`
MODIFY `attachments_only` BOOLEAN NOT NULL;
