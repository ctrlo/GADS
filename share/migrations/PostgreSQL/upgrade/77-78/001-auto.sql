-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/77/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/78/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ALTER COLUMN name_short TYPE character varying(64);

;
ALTER TABLE layout ADD CONSTRAINT layout_ux_instance_name_short UNIQUE (instance_id, name_short);

;

COMMIT;

