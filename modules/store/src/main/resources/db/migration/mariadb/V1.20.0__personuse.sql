ALTER TABLE `person`
ADD COLUMN `person_use` varchar(254);

UPDATE `person` SET `person_use` = 'concerning' where `concerning` = true;
UPDATE `person` SET `person_use` = 'correspondent' where `concerning` = false;
UPDATE `person` SET `person_use` = 'both' where `concerning` is null;

ALTER TABLE `person`
DROP COLUMN `concerning`;
