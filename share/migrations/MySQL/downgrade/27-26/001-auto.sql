-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/27/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view DROP COLUMN is_admin;

;

COMMIT;

