-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/74/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph ADD COLUMN is_shared smallint NOT NULL DEFAULT 0,
                  ADD COLUMN user_id bigint NULL,
                  ADD COLUMN group_id integer NULL,
                  ADD INDEX graph_idx_group_id (group_id),
                  ADD INDEX graph_idx_user_id (user_id),
                  ADD CONSTRAINT graph_fk_group_id FOREIGN KEY (group_id) REFERENCES `group` (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
                  ADD CONSTRAINT graph_fk_user_id FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

