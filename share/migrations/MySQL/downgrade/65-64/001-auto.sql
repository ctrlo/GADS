-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/65/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/64/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN remember_user_location;

;

COMMIT;

