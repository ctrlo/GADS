-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/34/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN forget_history;

;

COMMIT;

