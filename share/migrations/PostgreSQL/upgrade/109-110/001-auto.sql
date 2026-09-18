-- Convert schema '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/109/001-auto.yml' to '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN current_version_id bigint;

;
CREATE INDEX current_idx_current_version_id on current (current_version_id);

;
ALTER TABLE current ADD CONSTRAINT current_fk_current_version_id FOREIGN KEY (current_version_id)
  REFERENCES record (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE graph ADD COLUMN y_axis_link integer;

;
CREATE INDEX graph_idx_y_axis_link on graph (y_axis_link);

;
ALTER TABLE graph ADD CONSTRAINT graph_fk_y_axis_link FOREIGN KEY (y_axis_link)
  REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

