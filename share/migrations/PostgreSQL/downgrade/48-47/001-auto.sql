-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/48/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN forward_record_after_create;

;

COMMIT;

