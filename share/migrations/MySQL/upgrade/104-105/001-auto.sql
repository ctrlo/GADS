-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report CHANGE COLUMN name name text NOT NULL,
                   CHANGE COLUMN description description text NULL;

;

COMMIT;

