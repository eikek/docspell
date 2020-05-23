ALTER TABLE `collective`
ADD COLUMN (`integration_enabled` BOOLEAN);

UPDATE `collective` SET `integration_enabled` = true;

ALTER TABLE `collective`
MODIFY `integration_enabled` BOOLEAN NOT NULL;
