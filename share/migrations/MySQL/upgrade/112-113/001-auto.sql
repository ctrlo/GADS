-- Convert schema '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/112/001-auto.yml' to '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/113/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user ADD COLUMN created_by_id bigint NULL,
                 ADD INDEX user_idx_created_by_id (created_by_id),
                 ADD CONSTRAINT user_fk_created_by_id FOREIGN KEY (created_by_id) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

