-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/39/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN default_view_limit_extra_id integer;

;
CREATE INDEX instance_idx_default_view_limit_extra_id on instance (default_view_limit_extra_id);

;
ALTER TABLE instance ADD CONSTRAINT instance_fk_default_view_limit_extra_id FOREIGN KEY (default_view_limit_extra_id)
  REFERENCES view (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE view ADD COLUMN is_limit_extra smallint DEFAULT 0 NOT NULL;

;

COMMIT;

