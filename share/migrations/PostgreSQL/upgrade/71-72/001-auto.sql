-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/71/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/72/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN group_display character varying(45);

;

COMMIT;

