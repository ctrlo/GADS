-- Convert schema '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/109/001-auto.yml' to '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN current_version_id bigint NULL,
                    ADD INDEX current_idx_current_version_id (current_version_id),
                    ADD CONSTRAINT current_fk_current_version_id FOREIGN KEY (current_version_id) REFERENCES record (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE graph ADD COLUMN y_axis_link integer NULL,
                  ADD INDEX graph_idx_y_axis_link (y_axis_link),
                  ADD CONSTRAINT graph_fk_y_axis_link FOREIGN KEY (y_axis_link) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

