-- Convert schema '/root/GADS/share/migrations/_source/deploy/9/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user ADD COLUMN lastfail timestamp;

;
ALTER TABLE user ADD COLUMN failcount integer DEFAULT 0 NOT NULL;

;

COMMIT;

