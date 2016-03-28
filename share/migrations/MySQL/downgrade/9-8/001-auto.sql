-- Convert schema '/root/GADS/share/migrations/_source/deploy/9/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE string DROP INDEX string_idx_index,
                   DROP COLUMN value_index,
                   ADD INDEX string_idx_value (value(64));

;

COMMIT;

