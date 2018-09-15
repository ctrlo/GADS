-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/53/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/52/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sort DROP FOREIGN KEY sort_fk_parent_id,
                 DROP INDEX sort_idx_parent_id,
                 DROP COLUMN parent_id,
                 ADD INDEX sort_idx_layout_id (layout_id),
                 ADD CONSTRAINT sort_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

