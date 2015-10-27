-- Convert schema '/root/GADS/share/migrations/_source/deploy/2/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP COLUMN value_text;

;
ALTER TABLE calcval DROP COLUMN value_int;

;
ALTER TABLE calcval DROP COLUMN value_date;

;
ALTER TABLE instance ALTER COLUMN name TYPE character varying(256);

;
ALTER TABLE layout ADD COLUMN hidden smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE user DROP CONSTRAINT user_fk_limit_to_view;

;
DROP INDEX user_idx_limit_to_view;

;
DROP INDEX user_idx_email;

;
DROP INDEX user_idx_username;

;
ALTER TABLE user DROP COLUMN limit_to_view;

;
ALTER TABLE user ALTER COLUMN email TYPE character varying(256);

;
ALTER TABLE user ALTER COLUMN username TYPE character varying(256);

;
DROP TABLE curval CASCADE;

;
DROP TABLE curval_fields CASCADE;

;

COMMIT;

