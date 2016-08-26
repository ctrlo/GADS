-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE audit DROP CONSTRAINT audit_fk_site_id;

;
DROP INDEX audit_idx_site_id;

;
ALTER TABLE audit DROP COLUMN site_id;

;
ALTER TABLE "group" DROP CONSTRAINT group_fk_site_id;

;
DROP INDEX group_idx_site_id;

;
ALTER TABLE "group" DROP COLUMN site_id;

;
ALTER TABLE import DROP CONSTRAINT import_fk_site_id;

;
DROP INDEX import_idx_site_id;

;
ALTER TABLE import DROP COLUMN site_id;

;
ALTER TABLE instance DROP CONSTRAINT instance_fk_site_id;

;
DROP INDEX instance_idx_site_id;

;
ALTER TABLE instance DROP COLUMN site_id;

;
ALTER TABLE organisation DROP CONSTRAINT organisation_fk_site_id;

;
DROP INDEX organisation_idx_site_id;

;
ALTER TABLE organisation DROP COLUMN site_id;

;
ALTER TABLE title DROP CONSTRAINT title_fk_site_id;

;
DROP INDEX title_idx_site_id;

;
ALTER TABLE title DROP COLUMN site_id;

;
ALTER TABLE "user" DROP CONSTRAINT user_fk_site_id;

;
DROP INDEX user_idx_site_id;

;
ALTER TABLE "user" DROP COLUMN site_id;

;
DROP TABLE site CASCADE;

;

COMMIT;

