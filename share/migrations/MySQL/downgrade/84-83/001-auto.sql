-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/84/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dashboard DROP FOREIGN KEY dashboard_fk_site_id,
                      DROP INDEX dashboard_idx_site_id,
                      DROP COLUMN site_id;

;

COMMIT;

