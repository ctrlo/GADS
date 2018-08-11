-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/50/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/49/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval ADD CONSTRAINT calcval_ux_record_layout UNIQUE (record_id, layout_id);

;

COMMIT;

