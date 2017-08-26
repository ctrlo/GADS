-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN email_delete_text text;

;
ALTER TABLE instance ADD COLUMN email_delete_subject text;

;
ALTER TABLE instance ADD COLUMN email_reject_text text;

;
ALTER TABLE instance ADD COLUMN email_reject_subject text;

;
ALTER TABLE instance ADD COLUMN register_text text;

;
ALTER TABLE instance ADD COLUMN register_title_help text;

;
ALTER TABLE instance ADD COLUMN register_telephone_help text;

;
ALTER TABLE instance ADD COLUMN register_email_help text;

;
ALTER TABLE instance ADD COLUMN register_organisation_help text;

;
ALTER TABLE instance ADD COLUMN register_notes_help text;

;

COMMIT;

