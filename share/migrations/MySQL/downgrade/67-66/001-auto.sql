-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/66/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN register_team_help,
                 DROP COLUMN register_team_name,
                 DROP COLUMN register_show_team;

;
ALTER TABLE user DROP FOREIGN KEY user_fk_team_id,
                 DROP INDEX user_idx_team_id,
                 DROP COLUMN team_id;

;
ALTER TABLE team DROP FOREIGN KEY team_fk_site_id;

;
DROP TABLE team;

;

COMMIT;

