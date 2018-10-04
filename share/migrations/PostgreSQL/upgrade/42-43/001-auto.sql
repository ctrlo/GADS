-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/42/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN draftuser_id bigint;

;
CREATE INDEX current_idx_draftuser_id on current (draftuser_id);

;
ALTER TABLE current ADD CONSTRAINT current_fk_draftuser_id FOREIGN KEY (draftuser_id)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

