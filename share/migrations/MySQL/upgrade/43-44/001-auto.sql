-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/43/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/44/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph ADD COLUMN x_axis_link integer NULL,
                  ADD INDEX graph_idx_x_axis_link (x_axis_link),
                  ADD CONSTRAINT graph_fk_x_axis_link FOREIGN KEY (x_axis_link) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

