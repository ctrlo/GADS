-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/91/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/90/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE export DROP COLUMN result_internal;

;

COMMIT;

