-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE audit DROP FOREIGN KEY audit_fk_site_id,
                  DROP INDEX audit_idx_site_id,
                  DROP COLUMN site_id;

;
ALTER TABLE "group" DROP FOREIGN KEY group_fk_site_id,
                  DROP INDEX group_idx_site_id,
                  DROP COLUMN site_id;

;
ALTER TABLE import DROP FOREIGN KEY import_fk_site_id,
                   DROP INDEX import_idx_site_id,
                   DROP COLUMN site_id;

;
ALTER TABLE instance DROP FOREIGN KEY instance_fk_site_id,
                     DROP INDEX instance_idx_site_id,
                     DROP COLUMN site_id;

;
ALTER TABLE organisation DROP FOREIGN KEY organisation_fk_site_id,
                         DROP INDEX organisation_idx_site_id,
                         DROP COLUMN site_id;

;
ALTER TABLE title DROP FOREIGN KEY title_fk_site_id,
                  DROP INDEX title_idx_site_id,
                  DROP COLUMN site_id;

;
ALTER TABLE user DROP FOREIGN KEY user_fk_site_id,
                 DROP INDEX user_idx_site_id,
                 DROP COLUMN site_id;

;
DROP TABLE site;

;

COMMIT;

