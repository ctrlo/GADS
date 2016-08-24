-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE import DROP FOREIGN KEY import_fk_user_id;

;
DROP TABLE import;

;
ALTER TABLE import_row DROP FOREIGN KEY import_row_fk_import_id;

;
DROP TABLE import_row;

;

COMMIT;

