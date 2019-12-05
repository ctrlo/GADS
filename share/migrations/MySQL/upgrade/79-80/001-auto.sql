-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/79/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/80/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN hide_in_selector smallint NOT NULL DEFAULT 0;

;

COMMIT;

