-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/22/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN email_welcome_text text NULL,
                 ADD COLUMN email_welcome_subject text NULL,
                 ADD COLUMN email_delete_text text NULL,
                 ADD COLUMN email_delete_subject text NULL,
                 ADD COLUMN email_reject_text text NULL,
                 ADD COLUMN email_reject_subject text NULL,
                 ADD COLUMN register_text text NULL,
                 ADD COLUMN homepage_text text NULL,
                 ADD COLUMN homepage_text2 text NULL,
                 ADD COLUMN register_title_help text NULL,
                 ADD COLUMN register_freetext1_help text NULL,
                 ADD COLUMN register_freetext2_help text NULL,
                 ADD COLUMN register_email_help text NULL,
                 ADD COLUMN register_organisation_help text NULL,
                 ADD COLUMN register_organisation_name text NULL,
                 ADD COLUMN register_notes_help text NULL,
                 ADD COLUMN register_freetext1_name text NULL,
                 ADD COLUMN register_freetext2_name text NULL,
                 ADD COLUMN register_show_organisation smallint NOT NULL DEFAULT 1,
                 ADD COLUMN register_show_title smallint NOT NULL DEFAULT 1;

;
ALTER TABLE user ADD COLUMN freetext1 text NULL,
                 ADD COLUMN freetext2 text NULL;

;

COMMIT;

