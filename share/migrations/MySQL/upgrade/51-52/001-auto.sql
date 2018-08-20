-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/51/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/52/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN can_child smallint NOT NULL DEFAULT 0;

;

COMMIT;

