-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/53/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/52/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sort DROP CONSTRAINT sort_fk_parent_id;

;
DROP INDEX sort_idx_parent_id;

;
ALTER TABLE sort DROP COLUMN parent_id;

;
CREATE INDEX sort_idx_layout_id on sort (layout_id);

;
ALTER TABLE sort ADD CONSTRAINT sort_fk_layout_id FOREIGN KEY (layout_id)
  REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

