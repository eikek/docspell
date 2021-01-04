ALTER TABLE `userimap`
ADD COLUMN (`imap_oauth2` boolean);

UPDATE `userimap` SET `imap_oauth2` = false;

ALTER TABLE `userimap`
MODIFY `imap_oauth2` boolean NOT NULL;
