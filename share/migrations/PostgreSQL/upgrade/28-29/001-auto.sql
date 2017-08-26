-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/28/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN email_delete_text;

;
ALTER TABLE instance DROP COLUMN email_delete_subject;

;
ALTER TABLE instance DROP COLUMN email_reject_text;

;
ALTER TABLE instance DROP COLUMN email_reject_subject;

;
ALTER TABLE instance DROP COLUMN register_text;

;
ALTER TABLE instance DROP COLUMN register_title_help;

;
ALTER TABLE instance DROP COLUMN register_telephone_help;

;
ALTER TABLE instance DROP COLUMN register_email_help;

;
ALTER TABLE instance DROP COLUMN register_organisation_help;

;
ALTER TABLE instance DROP COLUMN register_notes_help;

;

COMMIT;

