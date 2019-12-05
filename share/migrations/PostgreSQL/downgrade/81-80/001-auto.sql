-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/81/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/80/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN no_download_pdf;

;
ALTER TABLE instance DROP COLUMN no_copy_record;

;

COMMIT;

