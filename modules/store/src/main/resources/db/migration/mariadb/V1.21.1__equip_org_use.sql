ALTER TABLE `equipment`
ADD COLUMN `equip_use` varchar(254);

UPDATE `equipment` SET `equip_use` = 'concerning';

ALTER TABLE `equipment`
ALTER COLUMN `equip_use` SET NOT NULL;


ALTER TABLE `organization`
ADD COLUMN `org_use` varchar(254);

UPDATE `organization` SET `org_use` = 'correspondent';

ALTER TABLE `organization`
ALTER COLUMN `org_use` SET NOT NULL;
