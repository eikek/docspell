ALTER TABLE `person`
ADD COLUMN `oid` varchar(254);

ALTER TABLE `person`
ADD CONSTRAINT fk_person_organization
FOREIGN KEY (`oid`)
REFERENCES `organization`(`oid`);
