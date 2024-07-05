-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP FOREIGN KEY calcval_fk_purged_by,
                    DROP INDEX calcval_idx_purged_by,
                    DROP COLUMN purged_by,
                    DROP COLUMN purged_on;

;
ALTER TABLE curval DROP FOREIGN KEY curval_fk_purged_by,
                   DROP INDEX curval_idx_purged_by,
                   DROP COLUMN purged_by,
                   DROP COLUMN purged_on;

;
ALTER TABLE daterange DROP FOREIGN KEY daterange_fk_purged_by,
                      DROP INDEX daterange_idx_purged_by,
                      DROP COLUMN purged_by,
                      DROP COLUMN purged_on;

;
ALTER TABLE enum DROP FOREIGN KEY enum_fk_purged_by,
                 DROP INDEX enum_idx_purged_by,
                 DROP COLUMN purged_by,
                 DROP COLUMN purged_on;

;
ALTER TABLE file DROP FOREIGN KEY file_fk_purged_by,
                 DROP INDEX file_idx_purged_by,
                 DROP COLUMN purged_by,
                 DROP COLUMN purged_on;

;
ALTER TABLE intgr DROP FOREIGN KEY intgr_fk_purged_by,
                  DROP INDEX intgr_idx_purged_by,
                  DROP COLUMN purged_by,
                  DROP COLUMN purged_on;

;
ALTER TABLE person DROP FOREIGN KEY person_fk_purged_by,
                   DROP INDEX person_idx_purged_by,
                   DROP COLUMN purged_by,
                   DROP COLUMN purged_on;

;
ALTER TABLE ragval DROP FOREIGN KEY ragval_fk_purged_by,
                   DROP INDEX ragval_idx_purged_by,
                   DROP COLUMN purged_by,
                   DROP COLUMN purged_on;

;
ALTER TABLE string DROP FOREIGN KEY string_fk_purged_by,
                   DROP INDEX string_idx_purged_by,
                   DROP COLUMN purged_by,
                   DROP COLUMN purged_on;

;

COMMIT;

