-- Convert schema '/home/droberts/source/GADS/share/migrations/_source/deploy/99/001-auto.yml' to '/home/droberts/source/GADS/share/migrations/_source/deploy/100/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN register_freetext1_placeholder text NULL,
                 ADD COLUMN register_freetext2_placeholder text NULL,
                 ADD COLUMN account_request_notes_name text NULL,
                 ADD COLUMN account_request_notes_placeholder text NULL;

;

COMMIT;

