ALTER TABLE `attachmentmeta`
ADD COLUMN (`language` varchar(254));

update `attachmentmeta` `m`
inner join (
    select `m`.`attachid`, `c`.`doclang`
    from `attachmentmeta` m
    inner join `attachment` a on `a`.`attachid` = `m`.`attachid`
    inner join `item` i on `a`.`itemid` = `i`.`itemid`
    inner join `collective` c on `c`.`cid` = `i`.`cid`
  ) as `c`
set `m`.`language` = `c`.`doclang`
where `m`.`attachid` = `c`.`attachid` and `m`.`language` is null;

