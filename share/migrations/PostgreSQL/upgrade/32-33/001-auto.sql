-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/32/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "user" DROP COLUMN telephone;

;

COMMIT;

