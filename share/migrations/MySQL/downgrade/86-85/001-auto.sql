-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/86/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/85/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE audit DROP FOREIGN KEY audit_fk_instance_id,
                  DROP INDEX audit_idx_instance_id,
                  DROP COLUMN instance_id;

;

COMMIT;

