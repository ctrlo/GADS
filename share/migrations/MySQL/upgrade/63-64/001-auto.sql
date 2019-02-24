-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/63/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/64/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE fileval ADD COLUMN edit_user_id bigint NULL,
                    ADD INDEX fileval_idx_edit_user_id (edit_user_id),
                    ADD CONSTRAINT fileval_fk_edit_user_id FOREIGN KEY (edit_user_id) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

