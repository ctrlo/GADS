-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/42/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN draftuser_id bigint NULL,
                    ADD INDEX current_idx_draftuser_id (draftuser_id),
                    ADD CONSTRAINT current_fk_draftuser_id FOREIGN KEY (draftuser_id) REFERENCES `user` (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

