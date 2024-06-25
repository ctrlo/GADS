-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE record DROP CONSTRAINT record_fk_purged_by;

;
DROP INDEX record_idx_purged_by;

;
ALTER TABLE record DROP COLUMN purged_on;

;
ALTER TABLE record DROP COLUMN purged_by;

;

COMMIT;

