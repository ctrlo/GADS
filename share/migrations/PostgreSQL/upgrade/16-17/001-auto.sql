-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "site" (
  "id" serial NOT NULL,
  "host" character varying(128),
  "created" timestamp,
  PRIMARY KEY ("id")
);

;
ALTER TABLE audit ADD COLUMN site_id integer;

;
CREATE INDEX audit_idx_site_id on audit (site_id);

;
ALTER TABLE audit ADD CONSTRAINT audit_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "group" ADD COLUMN site_id integer;

;
CREATE INDEX group_idx_site_id on "group" (site_id);

;
ALTER TABLE "group" ADD CONSTRAINT group_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE import ADD COLUMN site_id integer;

;
CREATE INDEX import_idx_site_id on import (site_id);

;
ALTER TABLE import ADD CONSTRAINT import_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE instance ADD COLUMN site_id integer;

;
CREATE INDEX instance_idx_site_id on instance (site_id);

;
ALTER TABLE instance ADD CONSTRAINT instance_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE organisation ADD COLUMN site_id integer;

;
CREATE INDEX organisation_idx_site_id on organisation (site_id);

;
ALTER TABLE organisation ADD CONSTRAINT organisation_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE title ADD COLUMN site_id integer;

;
CREATE INDEX title_idx_site_id on title (site_id);

;
ALTER TABLE title ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD COLUMN site_id integer;

;
CREATE INDEX user_idx_site_id on "user" (site_id);

;
ALTER TABLE "user" ADD CONSTRAINT user_fk_site_id FOREIGN KEY (site_id)
  REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

