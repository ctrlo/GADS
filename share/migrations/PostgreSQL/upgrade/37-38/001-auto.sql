-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/37/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/38/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN name_short character varying(64);

;

COMMIT;

