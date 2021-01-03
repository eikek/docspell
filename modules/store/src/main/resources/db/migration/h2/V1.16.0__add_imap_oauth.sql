ALTER TABLE "userimap"
ADD COLUMN "imap_oauth2" boolean NULL;

UPDATE "userimap" SET "imap_oauth2" = false;

ALTER TABLE "userimap"
ALTER COLUMN "imap_oauth2" SET NOT NULL;
