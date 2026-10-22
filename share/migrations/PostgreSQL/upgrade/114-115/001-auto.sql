-- Convert schema '/home/abeverley/git/GADS10/bin/../share/migrations/_source/deploy/114/001-auto.yml' to '/home/abeverley/git/GADS10/bin/../share/migrations/_source/deploy/115/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dashboard ADD COLUMN group_id integer;

;
ALTER TABLE dashboard ADD COLUMN type character varying(16);

;
CREATE INDEX dashboard_idx_group_id on dashboard (group_id);

;
ALTER TABLE dashboard ADD CONSTRAINT dashboard_fk_group_id FOREIGN KEY (group_id)
  REFERENCES "group" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE instance ADD COLUMN record_display character varying(16);

;
ALTER TABLE widget ADD COLUMN options text;

;

COMMIT;

