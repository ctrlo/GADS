-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/69/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/68/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN register_organisation_mandatory,
                 DROP COLUMN register_department_mandatory,
                 DROP COLUMN register_team_mandatory;

;

COMMIT;

