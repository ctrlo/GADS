-- Convert schema '/home/abeverley/git/GADS10/bin/../share/migrations/_source/deploy/115/001-auto.yml' to '/home/abeverley/git/GADS10/bin/../share/migrations/_source/deploy/114/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dashboard DROP FOREIGN KEY dashboard_fk_group_id,
                      DROP INDEX dashboard_idx_group_id,
                      DROP COLUMN group_id,
                      DROP COLUMN type;

;
ALTER TABLE instance DROP COLUMN record_display;

;
ALTER TABLE widget DROP COLUMN options;

;

COMMIT;

