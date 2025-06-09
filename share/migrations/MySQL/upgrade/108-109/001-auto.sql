-- Convert schema '/root/source/gads/bin/../share/migrations/_source/deploy/108/001-auto.yml' to '/root/source/gads/bin/../share/migrations/_source/deploy/109/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE file_option ADD COLUMN extra_values text NULL;

;

COMMIT;

