-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/14/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE alert_cache ADD COLUMN user_id bigint NULL,
                        ADD INDEX alert_cache_idx_user_id (user_id),
                        ADD CONSTRAINT alert_cache_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

