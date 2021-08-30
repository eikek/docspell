CREATE INDEX "joblog_id_created_idx" ON "joblog"("jid", "created");
CREATE INDEX "item_itemdate_created_idx" ON "item"(coalesce("itemdate", "created"));
