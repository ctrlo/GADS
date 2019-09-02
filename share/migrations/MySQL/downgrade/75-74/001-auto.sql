-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/74/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph DROP FOREIGN KEY graph_fk_group_id,
                  DROP FOREIGN KEY graph_fk_user_id,
                  DROP INDEX graph_idx_group_id,
                  DROP INDEX graph_idx_user_id,
                  DROP COLUMN is_shared,
                  DROP COLUMN user_id,
                  DROP COLUMN group_id;

;

COMMIT;

