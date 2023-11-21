-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/102/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/101/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP COLUMN notes;

;

COMMIT;

