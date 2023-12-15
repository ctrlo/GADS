-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/103/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report ADD COLUMN title varchar(128) NULL,
                   ADD COLUMN security_marking varchar(128) NULL,
                   ADD COLUMN security_marking_extra varchar(128) NULL;

;
ALTER TABLE site ADD COLUMN security_marking text NULL;

;

COMMIT;

