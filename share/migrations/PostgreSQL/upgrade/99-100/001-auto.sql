-- Convert schema '/home/droberts/source/gads2/share/migrations/_source/deploy/99/001-auto.yml' to '/home/droberts/source/gads2/share/migrations/_source/deploy/100/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN register_freetext1_placeholder text;

;
ALTER TABLE site ADD COLUMN register_freetext2_placeholder text;

;
ALTER TABLE site ADD COLUMN account_request_notes_name text;

;
ALTER TABLE site ADD COLUMN account_request_notes_placeholder text;

;

COMMIT;

