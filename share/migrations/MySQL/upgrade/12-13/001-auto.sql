-- Convert schema '/root/GADS/share/migrations/_source/deploy/12/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE curval ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE date ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE daterange ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE enum ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE file ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE intgr ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE person ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;
ALTER TABLE string ADD COLUMN child_unique smallint NOT NULL DEFAULT 0;

;

COMMIT;

