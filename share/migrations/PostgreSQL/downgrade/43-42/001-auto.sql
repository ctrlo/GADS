-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/43/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/42/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP CONSTRAINT current_fk_draftuser_id;

;
DROP INDEX current_idx_draftuser_id;

;
ALTER TABLE current DROP COLUMN draftuser_id;

;

COMMIT;

