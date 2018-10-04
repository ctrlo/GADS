-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/35/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view ADD COLUMN group_id integer;

;
CREATE INDEX view_idx_group_id on view (group_id);

;
ALTER TABLE view ADD CONSTRAINT view_fk_group_id FOREIGN KEY (group_id)
  REFERENCES "group" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

