-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/81/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN user_editable_fields text NULL;

;

COMMIT;

