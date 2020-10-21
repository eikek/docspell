ALTER TABLE "equipment"
ADD CONSTRAINT "equipment_cid_name_key"
UNIQUE ("cid", "name");
