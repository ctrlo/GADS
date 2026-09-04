-- Convert schema '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/113/001-auto.yml' to '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/112/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP FOREIGN KEY user_fk_created_by_id,
                 DROP INDEX user_idx_created_by_id,
                 DROP COLUMN created_by_id;

;

COMMIT;

