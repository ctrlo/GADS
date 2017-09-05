-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/28/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN email_delete_text,
                     DROP COLUMN email_delete_subject,
                     DROP COLUMN email_reject_text,
                     DROP COLUMN email_reject_subject,
                     DROP COLUMN register_text,
                     DROP COLUMN register_title_help,
                     DROP COLUMN register_telephone_help,
                     DROP COLUMN register_email_help,
                     DROP COLUMN register_organisation_help,
                     DROP COLUMN register_notes_help;

;

COMMIT;

