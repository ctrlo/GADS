-- Convert schema '/workspaces/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml' to '/workspaces/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc_unique DROP CONSTRAINT calc_unique_ux_layout_datetime,
                        DROP COLUMN value_datetime;

;
ALTER TABLE calcval DROP INDEX calcval_idx_value_datetime,
                    DROP COLUMN value_datetime;

;

COMMIT;

