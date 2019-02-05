-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/58/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/59/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN internal smallint NOT NULL DEFAULT 0;

;

COMMIT;

