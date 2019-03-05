-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/64/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/65/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN remember_user_location smallint NOT NULL DEFAULT 1;

;

COMMIT;

