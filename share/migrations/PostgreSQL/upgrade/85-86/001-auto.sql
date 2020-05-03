-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/85/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/86/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE audit ADD COLUMN instance_id integer;

;
CREATE INDEX audit_idx_instance_id on audit (instance_id);

;
ALTER TABLE audit ADD CONSTRAINT audit_fk_instance_id FOREIGN KEY (instance_id)
  REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

