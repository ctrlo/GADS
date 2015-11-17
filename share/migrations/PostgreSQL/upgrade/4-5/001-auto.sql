-- Convert schema '/root/GADS/share/migrations/_source/deploy/4/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
DROP INDEX calcval_idx_value;

;
ALTER TABLE calcval DROP COLUMN value;

;
CREATE INDEX calcval_idx_value_text on calcval (value_text);

;
CREATE INDEX calcval_idx_value_numeric on calcval (value_numeric);

;
CREATE INDEX calcval_idx_value_int on calcval (value_int);

;
CREATE INDEX calcval_idx_value_date on calcval (value_date);

;

COMMIT;

