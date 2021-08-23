ALTER TABLE "source"
ADD COLUMN "attachments_only" BOOLEAN NULL;

UPDATE "source"
SET  "attachments_only" = FALSE;

ALTER TABLE "source"
ALTER COLUMN "attachments_only" SET NOT NULL;
