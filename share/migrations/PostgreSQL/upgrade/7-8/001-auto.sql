-- Convert schema '/root/GADS/share/migrations/_source/deploy/7/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout ADD COLUMN textbox smallint DEFAULT 0 NOT NULL;

;

COMMIT;

