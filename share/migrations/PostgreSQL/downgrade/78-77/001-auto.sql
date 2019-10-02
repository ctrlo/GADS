-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/78/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/77/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP CONSTRAINT layout_ux_instance_name_short;

;
ALTER TABLE layout ALTER COLUMN name_short TYPE text;

;

COMMIT;

