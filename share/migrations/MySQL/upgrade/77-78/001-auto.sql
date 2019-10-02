-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/77/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/78/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout CHANGE COLUMN name_short name_short varchar(64) NULL,
                   ADD UNIQUE layout_ux_instance_name_short (instance_id, name_short);

;

COMMIT;

