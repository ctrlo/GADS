-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/74/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph DROP CONSTRAINT graph_fk_group_id;

;
ALTER TABLE graph DROP CONSTRAINT graph_fk_user_id;

;
DROP INDEX graph_idx_group_id;

;
DROP INDEX graph_idx_user_id;

;
ALTER TABLE graph DROP COLUMN is_shared;

;
ALTER TABLE graph DROP COLUMN user_id;

;
ALTER TABLE graph DROP COLUMN group_id;

;

COMMIT;

