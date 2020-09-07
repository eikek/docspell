ALTER TABLE "collective"
ADD COLUMN "integration_enabled" BOOLEAN;

UPDATE "collective" SET "integration_enabled" = true;

ALTER TABLE "collective"
ALTER COLUMN "integration_enabled" SET NOT NULL;
