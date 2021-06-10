-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/91/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/92/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE import ADD COLUMN instance_id integer NULL,
                   ADD INDEX import_idx_instance_id (instance_id),
                   ADD CONSTRAINT import_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

