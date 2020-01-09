-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/83/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dashboard ADD COLUMN site_id integer;

;
CREATE INDEX dashboard_idx_site_id on dashboard (site_id);

;
ALTER TABLE dashboard ADD CONSTRAINT dashboard_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

