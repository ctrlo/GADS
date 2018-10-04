-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/35/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view ADD COLUMN group_id integer NULL,
                 ADD INDEX view_idx_group_id (group_id),
                 ADD CONSTRAINT view_fk_group_id FOREIGN KEY (group_id) REFERENCES `group` (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

