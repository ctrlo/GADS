-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report ALTER COLUMN name TYPE text;

;
ALTER TABLE report ALTER COLUMN description TYPE text;

;

COMMIT;

