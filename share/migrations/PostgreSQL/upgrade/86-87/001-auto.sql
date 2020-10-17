-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/86/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/87/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view ADD COLUMN created timestamp;

;
ALTER TABLE view ADD COLUMN createdby bigint;

;
CREATE INDEX view_idx_createdby on view (createdby);

;
ALTER TABLE view ADD CONSTRAINT view_fk_createdby FOREIGN KEY (createdby)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

