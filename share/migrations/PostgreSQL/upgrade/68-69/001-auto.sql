-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/68/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/69/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN register_organisation_mandatory smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE site ADD COLUMN register_department_mandatory smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE site ADD COLUMN register_team_mandatory smallint DEFAULT 0 NOT NULL;

;

COMMIT;

