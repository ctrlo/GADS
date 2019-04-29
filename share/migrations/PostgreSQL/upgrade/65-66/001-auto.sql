-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/65/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/66/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN email_welcome_text;

;
ALTER TABLE instance DROP COLUMN email_welcome_subject;

;
ALTER TABLE site ADD COLUMN name text;

;

COMMIT;

