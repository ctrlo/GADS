-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/25/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP CONSTRAINT layout_fk_related_field;

;
DROP INDEX layout_idx_related_field;

;
ALTER TABLE layout DROP COLUMN related_field;

;

COMMIT;

