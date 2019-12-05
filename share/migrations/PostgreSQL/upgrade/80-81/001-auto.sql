-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/80/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/81/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN no_download_pdf smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE instance ADD COLUMN no_copy_record smallint DEFAULT 0 NOT NULL;

;

COMMIT;

