-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/11/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN typeahead smallint NOT NULL DEFAULT 0;

;

COMMIT;

