-- Convert schema '/root/GADS/share/migrations/_source/deploy/9/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
DROP INDEX string_idx_index;

;
ALTER TABLE string DROP COLUMN value_index;

;
CREATE INDEX string_idx_value on string (value);

;

COMMIT;

