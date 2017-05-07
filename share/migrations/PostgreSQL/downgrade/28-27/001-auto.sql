-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/28/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "user" DROP COLUMN session_settings;

;

COMMIT;

