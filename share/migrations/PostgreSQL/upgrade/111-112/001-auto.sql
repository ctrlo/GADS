-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/112/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "user" ADD COLUMN created_by text;

;

COMMIT;

