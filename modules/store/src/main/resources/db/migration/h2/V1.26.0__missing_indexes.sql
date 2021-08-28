CREATE INDEX "joblog_id_created_idx" ON "joblog"("jid", "created");
-- H2 doesn't support coalesce in create index
--CREATE INDEX "item_itemdate_created_idx" ON "item"(coalesce("itemdate", "created"));
