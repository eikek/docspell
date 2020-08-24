-- organization
ALTER TABLE "organization"
ADD COLUMN "updated" timestamp;

UPDATE "organization" SET "updated" = "created";

ALTER TABLE "organization"
ALTER COLUMN "updated" SET NOT NULL;

-- person
ALTER TABLE "person" ALTER COLUMN "created"
  TYPE timestamp USING(to_timestamp("created", 'YYYY-MM-DD HH24:MI:SS')::timestamp);

ALTER TABLE "person"
ADD COLUMN "updated" timestamp;

UPDATE "person" SET "updated" = "created";

ALTER TABLE "person"
ALTER COLUMN "updated" SET NOT NULL;

-- equipment
ALTER TABLE "equipment"
ADD COLUMN "updated" timestamp;

UPDATE "equipment" SET "updated" = "created";

ALTER TABLE "equipment"
ALTER COLUMN "updated" SET NOT NULL;
