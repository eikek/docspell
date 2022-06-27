alter table `rememberme` add column (`user_id` varchar(254));

update `rememberme` m
set `user_id` = (select `uid` from `user_` where `login` = m.`login` and `cid` = m.`cid`);

alter table `rememberme` modify `user_id` varchar(254) NOT NULL;

alter table `rememberme` drop foreign key `rememberme_ibfk_1`;
alter table `rememberme` drop column `login` cascade;
alter table `rememberme` drop column `cid` cascade;

create index `rememberme_user_id_idx` on `rememberme`(`user_id`);
alter table `rememberme` add constraint `remember_user_id_fk` foreign key(`user_id`) references `user_`(`uid`);
