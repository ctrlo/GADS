-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/42/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP INDEX current_ux_instance_serial,
                    DROP COLUMN serial;

;

COMMIT;

