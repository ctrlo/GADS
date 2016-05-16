-- Convert schema '/root/GADS/share/migrations/_source/deploy/12/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE curval ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE date ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE daterange ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE enum ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE file ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE intgr ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE person ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE string ADD COLUMN child_unique smallint DEFAULT 0 NOT NULL;

;

COMMIT;

