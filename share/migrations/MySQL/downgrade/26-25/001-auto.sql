-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/26/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view_limit DROP FOREIGN KEY view_limit_fk_user_id,
                       DROP FOREIGN KEY view_limit_fk_view_id;

;
DROP TABLE view_limit;

;

COMMIT;

