-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP CONSTRAINT current_fk_record_id;

;
DROP INDEX current_idx_record_id;

;
ALTER TABLE current DROP COLUMN record_id;

;

COMMIT;

