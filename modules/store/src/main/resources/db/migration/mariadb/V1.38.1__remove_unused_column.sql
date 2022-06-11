alter table `item` drop foreign key item_ibfk_1;
alter table `item` drop column `inreplyto` cascade;
