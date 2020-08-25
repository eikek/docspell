-- organization
ALTER TABLE `organization`
ADD COLUMN (`updated` timestamp);

UPDATE `organization` SET `updated` = `created`;

ALTER TABLE `organization`
MODIFY `updated` timestamp NOT NULL;

-- person
ALTER TABLE `person`
MODIFY `created` timestamp;

ALTER TABLE `person`
ADD COLUMN (`updated` timestamp);

UPDATE `person` SET `updated` = `created`;

ALTER TABLE `person`
MODIFY `updated` timestamp NOT NULL;

-- equipment
ALTER TABLE `equipment`
ADD COLUMN (`updated` timestamp);

UPDATE `equipment` SET `updated` = `created`;

ALTER TABLE `equipment`
MODIFY `updated` timestamp NOT NULL;
