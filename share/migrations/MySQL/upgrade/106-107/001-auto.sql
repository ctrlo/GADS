-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval ADD COLUMN purged_by bigint NULL,
                    ADD COLUMN purged_on datetime NULL,
                    ADD INDEX calcval_idx_purged_by (purged_by),
                    ADD CONSTRAINT calcval_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE curval ADD COLUMN purged_by bigint NULL,
                   ADD COLUMN purged_on datetime NULL,
                   ADD INDEX curval_idx_purged_by (purged_by),
                   ADD CONSTRAINT curval_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE date ADD COLUMN purged_by bigint NULL,
                 ADD COLUMN purged_on timestamp NULL,
                 ADD INDEX date_idx_purged_by (purged_by),
                 ADD CONSTRAINT date_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE daterange ADD COLUMN purged_by bigint NULL,
                      ADD COLUMN purged_on datetime NULL,
                      ADD INDEX daterange_idx_purged_by (purged_by),
                      ADD CONSTRAINT daterange_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE enum ADD COLUMN purged_by bigint NULL,
                 ADD COLUMN purged_on datetime NULL,
                 ADD INDEX enum_idx_purged_by (purged_by),
                 ADD CONSTRAINT enum_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE file ADD COLUMN purged_by bigint NULL,
                 ADD COLUMN purged_on datetime NULL,
                 ADD INDEX file_idx_purged_by (purged_by),
                 ADD CONSTRAINT file_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE intgr ADD COLUMN purged_by bigint NULL,
                  ADD COLUMN purged_on datetime NULL,
                  ADD INDEX intgr_idx_purged_by (purged_by),
                  ADD CONSTRAINT intgr_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE person ADD COLUMN purged_by bigint NULL,
                   ADD COLUMN purged_on datetime NULL,
                   ADD INDEX person_idx_purged_by (purged_by),
                   ADD CONSTRAINT person_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE ragval ADD COLUMN purged_by bigint NULL,
                   ADD COLUMN purged_on datetime NULL,
                   ADD INDEX ragval_idx_purged_by (purged_by),
                   ADD CONSTRAINT ragval_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE string ADD COLUMN purged_by bigint NULL,
                   ADD COLUMN purged_on datetime NULL,
                   ADD INDEX string_idx_purged_by (purged_by),
                   ADD CONSTRAINT string_fk_purged_by FOREIGN KEY (purged_by) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

