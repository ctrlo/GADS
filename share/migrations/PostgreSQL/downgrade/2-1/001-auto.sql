-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/2/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP CONSTRAINT current_fk_linked_id;

;
ALTER TABLE current DROP CONSTRAINT current_fk_parent_id;

;
DROP INDEX current_idx_linked_id;

;
DROP INDEX current_idx_parent_id;

;
ALTER TABLE current DROP COLUMN parent_id;

;
ALTER TABLE current DROP COLUMN linked_id;

;
ALTER TABLE graph DROP CONSTRAINT graph_fk_instance_id;

;
DROP INDEX graph_idx_instance_id;

;
ALTER TABLE graph DROP COLUMN instance_id;

;
ALTER TABLE layout DROP CONSTRAINT layout_fk_instance_id;

;
ALTER TABLE layout DROP CONSTRAINT layout_fk_link_parent;

;
DROP INDEX layout_idx_instance_id;

;
DROP INDEX layout_idx_link_parent;

;
ALTER TABLE layout DROP COLUMN instance_id;

;
ALTER TABLE layout DROP COLUMN link_parent;

;
ALTER TABLE metric_group DROP CONSTRAINT metric_group_fk_instance_id;

;
DROP INDEX metric_group_idx_instance_id;

;
ALTER TABLE metric_group DROP COLUMN instance_id;

;
ALTER TABLE view DROP CONSTRAINT view_fk_instance_id;

;
DROP INDEX view_idx_instance_id;

;
ALTER TABLE view DROP COLUMN instance_id;

;
DROP TABLE graph_color CASCADE;

;

COMMIT;

