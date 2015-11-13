-- Convert schema '/root/GADS/share/migrations/_source/deploy/3/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN stylesheet;

;

COMMIT;

