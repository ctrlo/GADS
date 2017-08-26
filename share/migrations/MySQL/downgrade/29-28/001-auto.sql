-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN email_delete_text text NULL,
                     ADD COLUMN email_delete_subject text NULL,
                     ADD COLUMN email_reject_text text NULL,
                     ADD COLUMN email_reject_subject text NULL,
                     ADD COLUMN register_text text NULL,
                     ADD COLUMN register_title_help text NULL,
                     ADD COLUMN register_telephone_help text NULL,
                     ADD COLUMN register_email_help text NULL,
                     ADD COLUMN register_organisation_help text NULL,
                     ADD COLUMN register_notes_help text NULL;

;

COMMIT;

