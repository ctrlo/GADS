-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/19/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN multivalue smallint DEFAULT 0 NOT NULL;

;

COMMIT;

