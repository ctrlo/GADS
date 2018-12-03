-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/54/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/53/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN created;

;

COMMIT;

