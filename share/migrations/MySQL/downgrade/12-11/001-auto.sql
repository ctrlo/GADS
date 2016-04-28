-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/12/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP COLUMN typeahead;

;

COMMIT;

