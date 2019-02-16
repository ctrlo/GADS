-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/60/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/61/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN display_matchtype text NULL;

;

COMMIT;

