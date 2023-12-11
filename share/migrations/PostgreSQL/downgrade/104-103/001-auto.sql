-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/103/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report DROP COLUMN title;

;
ALTER TABLE report DROP COLUMN security_marking;

;
ALTER TABLE report DROP COLUMN security_marking_addendum;

;
DROP TABLE report_defaults CASCADE;

;

COMMIT;

