-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/74/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph ADD COLUMN is_shared smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE graph ADD COLUMN user_id bigint;

;
ALTER TABLE graph ADD COLUMN group_id integer;

;
CREATE INDEX graph_idx_group_id on graph (group_id);

;
CREATE INDEX graph_idx_user_id on graph (user_id);

;
ALTER TABLE graph ADD CONSTRAINT graph_fk_group_id FOREIGN KEY (group_id)
  REFERENCES "group" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE graph ADD CONSTRAINT graph_fk_user_id FOREIGN KEY (user_id)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

