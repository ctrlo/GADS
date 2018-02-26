-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/31/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE group DROP COLUMN default_read,
                  DROP COLUMN default_write_new,
                  DROP COLUMN default_write_existing,
                  DROP COLUMN default_approve_new,
                  DROP COLUMN default_approve_existing,
                  DROP COLUMN default_write_new_no_approval,
                  DROP COLUMN default_write_existing_no_approval;

;

COMMIT;

