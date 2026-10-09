-- Convert schema '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml' to '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/109/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP CONSTRAINT current_fk_current_version_id;

;
DROP INDEX current_idx_current_version_id;

;
ALTER TABLE current DROP COLUMN current_version_id;

;
ALTER TABLE graph DROP CONSTRAINT graph_fk_y_axis_link;

;
DROP INDEX graph_idx_y_axis_link;

;
ALTER TABLE graph DROP COLUMN y_axis_link;

;

COMMIT;

