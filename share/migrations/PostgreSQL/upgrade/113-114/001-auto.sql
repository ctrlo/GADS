-- Convert schema '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/113/001-auto.yml' to '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/114/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc_unique ADD COLUMN value_datetime timestamp;

;
ALTER TABLE calc_unique ADD CONSTRAINT calc_unique_ux_layout_datetime UNIQUE (layout_id, value_datetime);

;
ALTER TABLE calcval ADD COLUMN value_datetime timestamp;

;
CREATE INDEX calcval_idx_value_datetime on calcval (value_datetime);

;

COMMIT;

