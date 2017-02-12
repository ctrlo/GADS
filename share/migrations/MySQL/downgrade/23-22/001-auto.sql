-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/23/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN email_welcome_text,
                 DROP COLUMN email_welcome_subject,
                 DROP COLUMN email_delete_text,
                 DROP COLUMN email_delete_subject,
                 DROP COLUMN email_reject_text,
                 DROP COLUMN email_reject_subject,
                 DROP COLUMN register_text,
                 DROP COLUMN homepage_text,
                 DROP COLUMN homepage_text2,
                 DROP COLUMN register_title_help,
                 DROP COLUMN register_freetext1_help,
                 DROP COLUMN register_freetext2_help,
                 DROP COLUMN register_email_help,
                 DROP COLUMN register_organisation_help,
                 DROP COLUMN register_organisation_name,
                 DROP COLUMN register_notes_help,
                 DROP COLUMN register_freetext1_name,
                 DROP COLUMN register_freetext2_name,
                 DROP COLUMN register_show_organisation,
                 DROP COLUMN register_show_title;

;
ALTER TABLE user DROP COLUMN freetext1,
                 DROP COLUMN freetext2;

;

COMMIT;

