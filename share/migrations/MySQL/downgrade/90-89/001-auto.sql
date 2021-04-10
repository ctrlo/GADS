-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/90/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/89/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE export DROP FOREIGN KEY export_fk_site_id,
                   DROP FOREIGN KEY export_fk_user_id;

;
DROP TABLE export;

;

COMMIT;

