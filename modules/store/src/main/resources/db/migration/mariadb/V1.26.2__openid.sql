ALTER TABLE `user_`
ADD COLUMN (`account_source` varchar(254));

UPDATE `user_`
SET `account_source` = 'local';

ALTER TABLE `user_`
MODIFY `account_source` varchar(254) NOT NULL;
