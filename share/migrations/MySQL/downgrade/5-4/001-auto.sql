-- Convert schema '/root/GADS/share/migrations/_source/deploy/5/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP INDEX calcval_idx_value_text,
                    DROP INDEX calcval_idx_value_numeric,
                    DROP INDEX calcval_idx_value_int,
                    DROP INDEX calcval_idx_value_date,
                    ADD COLUMN value text NULL,
                    ADD INDEX calcval_idx_value (value(64));

;

COMMIT;

