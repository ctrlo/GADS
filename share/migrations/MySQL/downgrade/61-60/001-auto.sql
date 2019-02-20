-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/61/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/60/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP COLUMN display_matchtype;

;

COMMIT;

