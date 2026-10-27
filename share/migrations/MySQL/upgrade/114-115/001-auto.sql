-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/114/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/115/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE file_option DROP FOREIGN KEY file_option_fk_layout_id;

;
DROP TABLE file_option;

;

COMMIT;

