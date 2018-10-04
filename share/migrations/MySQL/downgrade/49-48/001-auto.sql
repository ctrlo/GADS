-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/49/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/48/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE topic DROP COLUMN description;

;

COMMIT;

