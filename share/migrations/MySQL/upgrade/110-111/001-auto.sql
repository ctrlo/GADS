-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE file_option DROP FOREIGN KEY file_option_fk_layout_id;

;
DROP TABLE file_option;

;

COMMIT;

