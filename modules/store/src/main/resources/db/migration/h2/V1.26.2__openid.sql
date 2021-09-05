ALTER TABLE "user_"
ADD COLUMN "account_source" varchar(254);

UPDATE "user_"
SET  "account_source" = 'local';

ALTER TABLE "user_"
ALTER COLUMN "account_source" SET NOT NULL;
