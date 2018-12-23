-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/55/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/56/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN no_hide_blank smallint DEFAULT 0 NOT NULL;

;

COMMIT;

