-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/87/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/86/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view DROP CONSTRAINT view_fk_createdby;

;
DROP INDEX view_idx_createdby;

;
ALTER TABLE view DROP COLUMN created;

;
ALTER TABLE view DROP COLUMN createdby;

;

COMMIT;

