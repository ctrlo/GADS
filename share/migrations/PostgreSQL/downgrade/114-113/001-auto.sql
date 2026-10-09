-- Convert schema '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/114/001-auto.yml' to '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/113/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc_unique DROP CONSTRAINT calc_unique_ux_layout_datetime;

;
ALTER TABLE calc_unique DROP COLUMN value_datetime;

;
DROP INDEX calcval_idx_value_datetime;

;
ALTER TABLE calcval DROP COLUMN value_datetime;

;

COMMIT;

