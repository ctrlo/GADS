-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/24/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN related_field integer;

;
CREATE INDEX layout_idx_related_field on layout (related_field);

;
ALTER TABLE layout ADD CONSTRAINT layout_fk_related_field FOREIGN KEY (related_field)
  REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

