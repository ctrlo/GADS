-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/58/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/59/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN internal smallint DEFAULT 0 NOT NULL;

;

COMMIT;

