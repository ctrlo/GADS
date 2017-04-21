-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/26/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view ADD COLUMN is_admin smallint DEFAULT 0 NOT NULL;

;

COMMIT;

