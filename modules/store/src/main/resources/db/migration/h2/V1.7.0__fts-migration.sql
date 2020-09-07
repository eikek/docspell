CREATE TABLE "fts_migration" (
  "id" varchar(254) not null primary key,
  "version" int not null,
  "fts_engine" varchar(254) not null,
  "description" varchar(254) not null,
  "created" timestamp not null
);

CREATE UNIQUE INDEX "fts_migration_version_engine_idx"
ON "fts_migration"("version", "fts_engine");
