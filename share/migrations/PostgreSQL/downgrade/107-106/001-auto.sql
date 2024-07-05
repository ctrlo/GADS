-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP CONSTRAINT calcval_fk_purged_by;

;
DROP INDEX calcval_idx_purged_by;

;
ALTER TABLE calcval DROP COLUMN purged_by;

;
ALTER TABLE calcval DROP COLUMN purged_on;

;
ALTER TABLE curval DROP CONSTRAINT curval_fk_purged_by;

;
DROP INDEX curval_idx_purged_by;

;
ALTER TABLE curval DROP COLUMN purged_by;

;
ALTER TABLE curval DROP COLUMN purged_on;

;
ALTER TABLE daterange DROP CONSTRAINT daterange_fk_purged_by;

;
DROP INDEX daterange_idx_purged_by;

;
ALTER TABLE daterange DROP COLUMN purged_by;

;
ALTER TABLE daterange DROP COLUMN purged_on;

;
ALTER TABLE enum DROP CONSTRAINT enum_fk_purged_by;

;
DROP INDEX enum_idx_purged_by;

;
ALTER TABLE enum DROP COLUMN purged_by;

;
ALTER TABLE enum DROP COLUMN purged_on;

;
ALTER TABLE file DROP CONSTRAINT file_fk_purged_by;

;
DROP INDEX file_idx_purged_by;

;
ALTER TABLE file DROP COLUMN purged_by;

;
ALTER TABLE file DROP COLUMN purged_on;

;
ALTER TABLE intgr DROP CONSTRAINT intgr_fk_purged_by;

;
DROP INDEX intgr_idx_purged_by;

;
ALTER TABLE intgr DROP COLUMN purged_by;

;
ALTER TABLE intgr DROP COLUMN purged_on;

;
ALTER TABLE person DROP CONSTRAINT person_fk_purged_by;

;
DROP INDEX person_idx_purged_by;

;
ALTER TABLE person DROP COLUMN purged_by;

;
ALTER TABLE person DROP COLUMN purged_on;

;
ALTER TABLE ragval DROP CONSTRAINT ragval_fk_purged_by;

;
DROP INDEX ragval_idx_purged_by;

;
ALTER TABLE ragval DROP COLUMN purged_by;

;
ALTER TABLE ragval DROP COLUMN purged_on;

;
ALTER TABLE string DROP CONSTRAINT string_fk_purged_by;

;
DROP INDEX string_idx_purged_by;

;
ALTER TABLE string DROP COLUMN purged_by;

;
ALTER TABLE string DROP COLUMN purged_on;

;

COMMIT;

