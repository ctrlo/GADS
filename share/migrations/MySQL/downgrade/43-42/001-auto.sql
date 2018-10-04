-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/43/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/42/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP FOREIGN KEY current_fk_draftuser_id,
                    DROP INDEX current_idx_draftuser_id,
                    DROP COLUMN draftuser_id;

;

COMMIT;

