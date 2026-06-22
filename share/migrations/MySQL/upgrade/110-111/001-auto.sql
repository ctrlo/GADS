-- Convert schema '/workspaces/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml' to '/workspaces/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc_unique ADD COLUMN value_datetime datetime NULL,
                        ADD UNIQUE calc_unique_ux_layout_datetime (layout_id, value_datetime);

;
ALTER TABLE calcval ADD COLUMN value_datetime datetime NULL,
                    ADD INDEX calcval_idx_value_datetime (value_datetime);

;

COMMIT;

