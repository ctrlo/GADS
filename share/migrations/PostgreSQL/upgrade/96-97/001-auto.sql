-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/96/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/97/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN lookup_endpoint text;

;

COMMIT;

