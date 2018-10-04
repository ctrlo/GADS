-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/31/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN deleted timestamp;

;
ALTER TABLE current ADD COLUMN deletedby bigint;

;
CREATE INDEX current_idx_deletedby on current (deletedby);

;
ALTER TABLE current ADD CONSTRAINT current_fk_deletedby FOREIGN KEY (deletedby)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

