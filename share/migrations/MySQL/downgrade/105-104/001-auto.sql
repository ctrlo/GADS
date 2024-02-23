-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report CHANGE COLUMN name name varchar(128) NOT NULL,
                   CHANGE COLUMN description description varchar(128) NULL;

;

COMMIT;

