-- Convert schema '/home/droberts/source/GADS/share/migrations/_source/deploy/100/001-auto.yml' to '/home/droberts/source/GADS/share/migrations/_source/deploy/99/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN register_freetext1_placeholder;

;
ALTER TABLE site DROP COLUMN register_freetext2_placeholder;

;
ALTER TABLE site DROP COLUMN account_request_notes_name;

;
ALTER TABLE site DROP COLUMN account_request_notes_placeholder;

;

COMMIT;

