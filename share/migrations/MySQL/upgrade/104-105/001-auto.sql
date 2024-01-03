-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN security_marking varchar(45) NULL;

;
ALTER TABLE report ADD COLUMN security_marking varchar(128) NULL;

;
ALTER TABLE site ADD COLUMN security_marking text NULL,
                 ADD COLUMN site_logo longblob NULL;

;

COMMIT;

