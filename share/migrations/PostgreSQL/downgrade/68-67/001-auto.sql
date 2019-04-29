-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/68/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP COLUMN display_condition;

;
DROP TABLE display_field CASCADE;

;

COMMIT;

