-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/88/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/87/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE department DROP COLUMN deleted;

;
ALTER TABLE organisation DROP COLUMN deleted;

;
ALTER TABLE team DROP COLUMN deleted;

;
ALTER TABLE title DROP COLUMN deleted;

;

COMMIT;

