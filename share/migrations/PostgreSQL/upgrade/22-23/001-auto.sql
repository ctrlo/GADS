-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/22/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN email_welcome_text text;

;
ALTER TABLE site ADD COLUMN email_welcome_subject text;

;
ALTER TABLE site ADD COLUMN email_delete_text text;

;
ALTER TABLE site ADD COLUMN email_delete_subject text;

;
ALTER TABLE site ADD COLUMN email_reject_text text;

;
ALTER TABLE site ADD COLUMN email_reject_subject text;

;
ALTER TABLE site ADD COLUMN register_text text;

;
ALTER TABLE site ADD COLUMN homepage_text text;

;
ALTER TABLE site ADD COLUMN homepage_text2 text;

;
ALTER TABLE site ADD COLUMN register_title_help text;

;
ALTER TABLE site ADD COLUMN register_freetext1_help text;

;
ALTER TABLE site ADD COLUMN register_freetext2_help text;

;
ALTER TABLE site ADD COLUMN register_email_help text;

;
ALTER TABLE site ADD COLUMN register_organisation_help text;

;
ALTER TABLE site ADD COLUMN register_organisation_name text;

;
ALTER TABLE site ADD COLUMN register_notes_help text;

;
ALTER TABLE site ADD COLUMN register_freetext1_name text;

;
ALTER TABLE site ADD COLUMN register_freetext2_name text;

;
ALTER TABLE site ADD COLUMN register_show_organisation smallint DEFAULT 1 NOT NULL;

;
ALTER TABLE site ADD COLUMN register_show_title smallint DEFAULT 1 NOT NULL;

;
ALTER TABLE "user" ADD COLUMN freetext1 text;

;
ALTER TABLE "user" ADD COLUMN freetext2 text;

;

COMMIT;

