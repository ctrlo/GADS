-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP FOREIGN KEY current_fk_record_id,
                    DROP INDEX current_idx_record_id,
                    DROP COLUMN record_id;

;

COMMIT;

