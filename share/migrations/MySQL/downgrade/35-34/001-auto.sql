-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/35/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph DROP COLUMN as_percent;

;

COMMIT;

