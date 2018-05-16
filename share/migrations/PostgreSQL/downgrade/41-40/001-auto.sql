-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/41/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP CONSTRAINT instance_fk_api_index_layout_id;

;
DROP INDEX instance_idx_api_index_layout_id;

;
ALTER TABLE instance DROP COLUMN api_index_layout_id;

;

COMMIT;

