-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/51/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/50/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN hide_account_request;

;

COMMIT;

