-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/95/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/96/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN record_name text;

;

COMMIT;

