-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/70/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/69/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sort DROP CONSTRAINT sort_fk_layout_id;

;
DROP INDEX sort_idx_layout_id;

;
ALTER TABLE sort DROP COLUMN "order";

;
DROP TABLE view_group CASCADE;

;

COMMIT;

