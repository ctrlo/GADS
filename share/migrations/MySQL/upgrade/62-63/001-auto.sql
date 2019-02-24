-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/62/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/63/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE fileval ADD COLUMN is_independent smallint NOT NULL DEFAULT 0;

;

COMMIT;

