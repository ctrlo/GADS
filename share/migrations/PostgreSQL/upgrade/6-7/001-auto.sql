-- Convert schema '/root/GADS/share/migrations/_source/deploy/6/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN isunique smallint DEFAULT 0 NOT NULL;

;

COMMIT;

