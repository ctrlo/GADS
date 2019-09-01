-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/73/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/74/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE widget ADD COLUMN title text;

;

COMMIT;

