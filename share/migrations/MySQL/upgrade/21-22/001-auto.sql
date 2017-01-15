-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/21/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN filter text NULL;

;

COMMIT;

