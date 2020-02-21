-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/85/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE filtered_value DROP CONSTRAINT ux_submission_layout_current;

;

COMMIT;

