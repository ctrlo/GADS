-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/70/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/71/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN aggregate varchar(45) NULL;

;

COMMIT;

