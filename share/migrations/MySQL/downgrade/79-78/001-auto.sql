-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/79/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/78/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE submission;

;
ALTER TABLE filtered_value DROP FOREIGN KEY filtered_value_fk_current_id,
                           DROP FOREIGN KEY filtered_value_fk_layout_id,
                           DROP FOREIGN KEY filtered_value_fk_submission_id;

;
DROP TABLE filtered_value;

;

COMMIT;

