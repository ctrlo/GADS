-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/2/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current DROP FOREIGN KEY current_fk_linked_id,
                    DROP FOREIGN KEY current_fk_parent_id,
                    DROP INDEX current_idx_linked_id,
                    DROP INDEX current_idx_parent_id,
                    DROP COLUMN parent_id,
                    DROP COLUMN linked_id;

;
ALTER TABLE graph DROP FOREIGN KEY graph_fk_instance_id,
                  DROP INDEX graph_idx_instance_id,
                  DROP COLUMN instance_id;

;
ALTER TABLE layout DROP FOREIGN KEY layout_fk_instance_id,
                   DROP FOREIGN KEY layout_fk_link_parent,
                   DROP INDEX layout_idx_instance_id,
                   DROP INDEX layout_idx_link_parent,
                   DROP COLUMN instance_id,
                   DROP COLUMN link_parent;

;
ALTER TABLE metric_group DROP FOREIGN KEY metric_group_fk_instance_id,
                         DROP INDEX metric_group_idx_instance_id,
                         DROP COLUMN instance_id;

;
ALTER TABLE view DROP FOREIGN KEY view_fk_instance_id,
                 DROP INDEX view_idx_instance_id,
                 DROP COLUMN instance_id;

;
DROP TABLE graph_color;

;

COMMIT;

