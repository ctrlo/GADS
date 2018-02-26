-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/32/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP FOREIGN KEY current_fk_deletedby,
                    DROP INDEX current_idx_deletedby,
                    DROP COLUMN deleted,
                    DROP COLUMN deletedby;

;

COMMIT;

