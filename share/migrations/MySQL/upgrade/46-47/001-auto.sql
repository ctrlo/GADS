-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/46/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE enumval ADD COLUMN position integer NULL;

;

COMMIT;

