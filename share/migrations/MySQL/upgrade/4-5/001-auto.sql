-- Convert schema '/root/GADS/share/migrations/_source/deploy/4/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP INDEX calcval_idx_value,
                    DROP COLUMN value,
                    ADD INDEX calcval_idx_value_text (value_text(64)),
                    ADD INDEX calcval_idx_value_numeric (value_numeric),
                    ADD INDEX calcval_idx_value_int (value_int),
                    ADD INDEX calcval_idx_value_date (value_date);

;

COMMIT;

