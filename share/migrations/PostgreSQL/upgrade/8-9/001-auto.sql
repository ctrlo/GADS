-- Convert schema '/root/GADS/share/migrations/_source/deploy/8/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
DROP INDEX string_idx_value;

;
ALTER TABLE string ADD COLUMN value_index character varying(128);

;
CREATE INDEX string_idx_index on string (value_index);

;

COMMIT;

