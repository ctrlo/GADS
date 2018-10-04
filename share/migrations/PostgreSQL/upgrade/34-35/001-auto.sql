-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/34/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph ADD COLUMN as_percent smallint DEFAULT 0 NOT NULL;

;

COMMIT;

