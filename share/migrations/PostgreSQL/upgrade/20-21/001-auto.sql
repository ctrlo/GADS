-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/20/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc ADD COLUMN code text;

;
ALTER TABLE rag ADD COLUMN code text;

;

COMMIT;

