-- Convert schema '/root/GADS/share/migrations/_source/deploy/8/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE string DROP INDEX string_idx_value,
                   ADD COLUMN value_index varchar(128) NULL,
                   ADD INDEX string_idx_index (value_index);

;

COMMIT;

