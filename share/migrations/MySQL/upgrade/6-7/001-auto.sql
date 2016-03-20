-- Convert schema '/root/GADS/share/migrations/_source/deploy/6/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN isunique smallint NOT NULL DEFAULT 0;

;

COMMIT;

