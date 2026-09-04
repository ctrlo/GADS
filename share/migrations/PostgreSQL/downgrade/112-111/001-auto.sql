-- Convert schema '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/112/001-auto.yml' to '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view DROP COLUMN is_limit_override;

;

COMMIT;

