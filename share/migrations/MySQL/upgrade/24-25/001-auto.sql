-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/24/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN related_field integer NULL,
                   ADD INDEX layout_idx_related_field (related_field),
                   ADD CONSTRAINT layout_fk_related_field FOREIGN KEY (related_field) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

