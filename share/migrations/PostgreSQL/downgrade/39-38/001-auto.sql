-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/39/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/38/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN no_overnight_update;

;

COMMIT;

