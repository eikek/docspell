ALTER TABLE `equipment`
ADD COLUMN `equip_use` varchar(254);

UPDATE `equipment` SET `equip_use` = 'concerning';

ALTER TABLE `equipment`
MODIFY COLUMN `equip_use` varchar(254) NOT NULL;


ALTER TABLE `organization`
ADD COLUMN `org_use` varchar(254);

UPDATE `organization` SET `org_use` = 'correspondent';

ALTER TABLE `organization`
MODIFY COLUMN `org_use` varchar(254) NOT NULL;
