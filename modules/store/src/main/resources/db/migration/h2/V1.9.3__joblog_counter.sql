ALTER TABLE "joblog"
ADD COLUMN "counter" bigint generated always as identity;
