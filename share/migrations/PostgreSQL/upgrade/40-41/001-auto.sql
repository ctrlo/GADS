-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/40/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN api_index_layout_id integer;

;
CREATE INDEX instance_idx_api_index_layout_id on instance (api_index_layout_id);

;
ALTER TABLE instance ADD CONSTRAINT instance_fk_api_index_layout_id FOREIGN KEY (api_index_layout_id)
  REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

