CREATE TABLE "attachment_archive" (
  "id" varchar(254) not null primary key,
  "file_id" varchar(254) not null,
  "filename" varchar(254),
  "message_id" varchar(254),
  "created" timestamp not null,
  foreign key ("file_id") references "filemeta"("id"),
  foreign key ("id") references "attachment"("attachid")
);

CREATE INDEX "attachment_archive_message_id_idx"
ON "attachment_archive"("message_id");
