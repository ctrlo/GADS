-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/23/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN email_welcome_text;

;
ALTER TABLE site DROP COLUMN email_welcome_subject;

;
ALTER TABLE site DROP COLUMN email_delete_text;

;
ALTER TABLE site DROP COLUMN email_delete_subject;

;
ALTER TABLE site DROP COLUMN email_reject_text;

;
ALTER TABLE site DROP COLUMN email_reject_subject;

;
ALTER TABLE site DROP COLUMN register_text;

;
ALTER TABLE site DROP COLUMN homepage_text;

;
ALTER TABLE site DROP COLUMN homepage_text2;

;
ALTER TABLE site DROP COLUMN register_title_help;

;
ALTER TABLE site DROP COLUMN register_freetext1_help;

;
ALTER TABLE site DROP COLUMN register_freetext2_help;

;
ALTER TABLE site DROP COLUMN register_email_help;

;
ALTER TABLE site DROP COLUMN register_organisation_help;

;
ALTER TABLE site DROP COLUMN register_organisation_name;

;
ALTER TABLE site DROP COLUMN register_notes_help;

;
ALTER TABLE site DROP COLUMN register_freetext1_name;

;
ALTER TABLE site DROP COLUMN register_freetext2_name;

;
ALTER TABLE site DROP COLUMN register_show_organisation;

;
ALTER TABLE site DROP COLUMN register_show_title;

;
ALTER TABLE "user" DROP COLUMN freetext1;

;
ALTER TABLE "user" DROP COLUMN freetext2;

;

COMMIT;

