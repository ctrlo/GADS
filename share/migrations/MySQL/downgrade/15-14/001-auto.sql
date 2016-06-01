-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/15/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE alert_cache DROP FOREIGN KEY alert_cache_fk_user_id,
                        DROP INDEX alert_cache_idx_user_id,
                        DROP COLUMN user_id;

;

COMMIT;

