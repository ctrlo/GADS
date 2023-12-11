-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/103/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report ADD COLUMN title character varying(128) NOT NULL;

;
ALTER TABLE report ADD COLUMN security_marking character varying(128);

;
ALTER TABLE report ADD COLUMN security_marking_addendum character varying(128);

;

COMMIT;

