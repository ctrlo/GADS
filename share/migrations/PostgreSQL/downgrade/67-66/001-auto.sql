-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/66/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN register_team_help;

;
ALTER TABLE site DROP COLUMN register_team_name;

;
ALTER TABLE site DROP COLUMN register_show_team;

;
ALTER TABLE "user" DROP CONSTRAINT user_fk_team_id;

;
DROP INDEX user_idx_team_id;

;
ALTER TABLE "user" DROP COLUMN team_id;

;
DROP TABLE team CASCADE;

;

COMMIT;

