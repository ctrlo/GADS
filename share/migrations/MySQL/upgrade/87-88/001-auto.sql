-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/87/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/88/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE department ADD COLUMN deleted smallint NOT NULL DEFAULT 0;

;
ALTER TABLE organisation ADD COLUMN deleted smallint NOT NULL DEFAULT 0;

;
ALTER TABLE team ADD COLUMN deleted smallint NOT NULL DEFAULT 0;

;
ALTER TABLE title ADD COLUMN deleted smallint NOT NULL DEFAULT 0;

;

COMMIT;

