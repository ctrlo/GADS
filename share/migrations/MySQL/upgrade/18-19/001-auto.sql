-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/18/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN name_short text NULL;

;

COMMIT;

