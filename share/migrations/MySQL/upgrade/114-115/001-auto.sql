-- Convert schema '/home/abeverley/git/GADS10/bin/../share/migrations/_source/deploy/114/001-auto.yml' to '/home/abeverley/git/GADS10/bin/../share/migrations/_source/deploy/115/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dashboard ADD COLUMN group_id integer NULL,
                      ADD COLUMN type varchar(16) NULL,
                      ADD INDEX dashboard_idx_group_id (group_id),
                      ADD CONSTRAINT dashboard_fk_group_id FOREIGN KEY (group_id) REFERENCES group (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE instance ADD COLUMN record_display varchar(16) NULL;

;
ALTER TABLE widget ADD COLUMN options text NULL;

;

COMMIT;

