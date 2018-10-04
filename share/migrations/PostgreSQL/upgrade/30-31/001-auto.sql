-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/30/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "group" ADD COLUMN default_read smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "group" ADD COLUMN default_write_new smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "group" ADD COLUMN default_write_existing smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "group" ADD COLUMN default_approve_new smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "group" ADD COLUMN default_approve_existing smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "group" ADD COLUMN default_write_new_no_approval smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "group" ADD COLUMN default_write_existing_no_approval smallint DEFAULT 0 NOT NULL;

;

COMMIT;

