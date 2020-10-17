-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/87/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/88/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE department ADD COLUMN deleted smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE organisation ADD COLUMN deleted smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE team ADD COLUMN deleted smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE title ADD COLUMN deleted smallint DEFAULT 0 NOT NULL;

;

COMMIT;

