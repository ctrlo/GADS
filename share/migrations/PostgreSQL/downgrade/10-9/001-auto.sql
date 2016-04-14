-- Convert schema '/root/GADS/share/migrations/_source/deploy/10/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user DROP COLUMN lastfail;

;
ALTER TABLE user DROP COLUMN failcount;

;

COMMIT;

