ALTER TABLE "attachmentmeta"
ADD COLUMN "language" varchar(254);

update "attachmentmeta"
set "language" = 'deu'
where "attachid" in (
  select "m"."attachid"
  from "attachmentmeta" m
  inner join "attachment" a on "a"."attachid" = "m"."attachid"
  inner join "item" i on "a"."itemid" = "i"."itemid"
  inner join "collective" c on "c"."cid" = "i"."cid"
  where "c"."doclang" = 'deu'
);

update "attachmentmeta"
set "language" = 'eng'
where "attachid" in (
  select "m"."attachid"
  from "attachmentmeta" m
  inner join "attachment" a on "a"."attachid" = "m"."attachid"
  inner join "item" i on "a"."itemid" = "i"."itemid"
  inner join "collective" c on "c"."cid" = "i"."cid"
  where "c"."doclang" = 'eng'
);

update "attachmentmeta"
set "language" = 'fra'
where "attachid" in (
  select "m"."attachid"
  from "attachmentmeta" m
  inner join "attachment" a on "a"."attachid" = "m"."attachid"
  inner join "item" i on "a"."itemid" = "i"."itemid"
  inner join "collective" c on "c"."cid" = "i"."cid"
  where "c"."doclang" = 'fra'
);
