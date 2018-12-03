-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/55/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/54/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN debug_login;

;

COMMIT;

