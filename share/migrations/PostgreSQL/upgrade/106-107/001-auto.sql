-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval ADD COLUMN purged_by bigint;

;
ALTER TABLE calcval ADD COLUMN purged_on timestamp;

;
CREATE INDEX calcval_idx_purged_by on calcval (purged_by);

;
ALTER TABLE calcval ADD CONSTRAINT calcval_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE curval ADD COLUMN purged_by bigint;

;
ALTER TABLE curval ADD COLUMN purged_on timestamp;

;
CREATE INDEX curval_idx_purged_by on curval (purged_by);

;
ALTER TABLE curval ADD CONSTRAINT curval_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE date ADD COLUMN purged_by bigint;

;
ALTER TABLE date ADD COLUMN purged_on timestamp;

;
CREATE INDEX date_idx_purged_by on date (purged_by);

;
ALTER TABLE date ADD CONSTRAINT date_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE daterange ADD COLUMN purged_by bigint;

;
ALTER TABLE daterange ADD COLUMN purged_on timestamp;

;
CREATE INDEX daterange_idx_purged_by on daterange (purged_by);

;
ALTER TABLE daterange ADD CONSTRAINT daterange_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE enum ADD COLUMN purged_by bigint;

;
ALTER TABLE enum ADD COLUMN purged_on timestamp;

;
CREATE INDEX enum_idx_purged_by on enum (purged_by);

;
ALTER TABLE enum ADD CONSTRAINT enum_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE file ADD COLUMN purged_by bigint;

;
ALTER TABLE file ADD COLUMN purged_on timestamp;

;
CREATE INDEX file_idx_purged_by on file (purged_by);

;
ALTER TABLE file ADD CONSTRAINT file_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE intgr ADD COLUMN purged_by bigint;

;
ALTER TABLE intgr ADD COLUMN purged_on timestamp;

;
CREATE INDEX intgr_idx_purged_by on intgr (purged_by);

;
ALTER TABLE intgr ADD CONSTRAINT intgr_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE person ADD COLUMN purged_by bigint;

;
ALTER TABLE person ADD COLUMN purged_on timestamp;

;
CREATE INDEX person_idx_purged_by on person (purged_by);

;
ALTER TABLE person ADD CONSTRAINT person_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE ragval ADD COLUMN purged_by bigint;

;
ALTER TABLE ragval ADD COLUMN purged_on timestamp;

;
CREATE INDEX ragval_idx_purged_by on ragval (purged_by);

;
ALTER TABLE ragval ADD CONSTRAINT ragval_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE string ADD COLUMN purged_by bigint;

;
ALTER TABLE string ADD COLUMN purged_on timestamp;

;
CREATE INDEX string_idx_purged_by on string (purged_by);

;
ALTER TABLE string ADD CONSTRAINT string_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

