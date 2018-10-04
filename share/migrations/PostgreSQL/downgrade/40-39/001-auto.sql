-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/40/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/39/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP CONSTRAINT instance_fk_default_view_limit_extra_id;

;
DROP INDEX instance_idx_default_view_limit_extra_id;

;
ALTER TABLE instance DROP COLUMN default_view_limit_extra_id;

;
ALTER TABLE view DROP COLUMN is_limit_extra;

;

COMMIT;

