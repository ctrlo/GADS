-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/59/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/60/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN width integer DEFAULT 50 NOT NULL;

;

COMMIT;

