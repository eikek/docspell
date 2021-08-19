-- note this is only for users of nightly releases
DELETE FROM "periodic_task"
WHERE "task" = 'empty-trash';
