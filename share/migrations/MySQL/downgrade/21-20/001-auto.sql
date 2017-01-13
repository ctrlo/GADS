-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/21/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc DROP COLUMN code;

;
ALTER TABLE rag DROP COLUMN code;

;

COMMIT;

