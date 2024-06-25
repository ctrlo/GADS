-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE record ADD COLUMN purged_on timestamp;

;
ALTER TABLE record ADD COLUMN purged_by bigint;

;
CREATE INDEX record_idx_purged_by on record (purged_by);

;
ALTER TABLE record ADD CONSTRAINT record_fk_purged_by FOREIGN KEY (purged_by)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

