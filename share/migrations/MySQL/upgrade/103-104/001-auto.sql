-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/103/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report ADD COLUMN title varchar(128) NOT NULL,
                   ADD COLUMN security_marking varchar(128) NULL,
                   ADD COLUMN security_marking_addendum varchar(128) NULL;

;

COMMIT;

