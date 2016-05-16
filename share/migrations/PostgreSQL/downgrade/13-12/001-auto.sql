-- Convert schema '/root/GADS/share/migrations/_source/deploy/13/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE curval DROP COLUMN child_unique;

;
ALTER TABLE date DROP COLUMN child_unique;

;
ALTER TABLE daterange DROP COLUMN child_unique;

;
ALTER TABLE enum DROP COLUMN child_unique;

;
ALTER TABLE file DROP COLUMN child_unique;

;
ALTER TABLE intgr DROP COLUMN child_unique;

;
ALTER TABLE person DROP COLUMN child_unique;

;
ALTER TABLE string DROP COLUMN child_unique;

;

COMMIT;

