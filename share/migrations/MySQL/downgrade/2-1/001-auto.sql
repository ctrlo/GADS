-- Convert schema '/root/GADS/share/migrations/_source/deploy/2/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP COLUMN value_text,
                    DROP COLUMN value_int,
                    DROP COLUMN value_date;

;
ALTER TABLE instance CHANGE COLUMN name name text NULL;

;
ALTER TABLE layout ADD COLUMN hidden smallint NOT NULL DEFAULT 0;

;
ALTER TABLE user DROP FOREIGN KEY user_fk_limit_to_view,
                 DROP INDEX user_idx_limit_to_view,
                 DROP INDEX user_idx_email,
                 DROP INDEX user_idx_username,
                 DROP COLUMN limit_to_view,
                 CHANGE COLUMN email email text NULL,
                 CHANGE COLUMN username username text NULL;

;
ALTER TABLE curval DROP FOREIGN KEY curval_fk_layout_id,
                   DROP FOREIGN KEY curval_fk_record_id,
                   DROP FOREIGN KEY curval_fk_value;

;
DROP TABLE curval;

;
ALTER TABLE curval_fields DROP FOREIGN KEY curval_fields_fk_child_id,
                          DROP FOREIGN KEY curval_fields_fk_parent_id;

;
DROP TABLE curval_fields;

;

COMMIT;

