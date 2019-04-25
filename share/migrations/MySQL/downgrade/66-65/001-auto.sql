-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/66/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/65/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN email_welcome_text text NULL,
                     ADD COLUMN email_welcome_subject text NULL;

;
ALTER TABLE site DROP COLUMN name;

;

COMMIT;

