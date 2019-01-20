-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/58/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/57/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN register_department_help;

;
ALTER TABLE site DROP COLUMN register_department_name;

;
ALTER TABLE site DROP COLUMN register_show_department;

;
ALTER TABLE "user" DROP CONSTRAINT user_fk_department_id;

;
DROP INDEX user_idx_department_id;

;
ALTER TABLE "user" DROP COLUMN department_id;

;
DROP TABLE department CASCADE;

;

COMMIT;

