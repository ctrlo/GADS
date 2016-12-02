-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/18/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN record_id bigint;

;
CREATE INDEX current_idx_record_id on current (record_id);

;
ALTER TABLE current ADD CONSTRAINT current_fk_record_id FOREIGN KEY (record_id)
  REFERENCES record (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

