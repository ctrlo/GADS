-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/1/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `graph_color` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `color` char(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE `ux_graph_color_name` (`name`)
);

;
SET foreign_key_checks=1;

;
ALTER TABLE current ADD COLUMN parent_id integer NULL,
                    ADD COLUMN linked_id integer NULL,
                    ADD INDEX current_idx_linked_id (linked_id),
                    ADD INDEX current_idx_parent_id (parent_id),
                    ADD CONSTRAINT current_fk_linked_id FOREIGN KEY (linked_id) REFERENCES current (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
                    ADD CONSTRAINT current_fk_parent_id FOREIGN KEY (parent_id) REFERENCES current (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE graph ADD COLUMN instance_id integer NULL,
                  ADD INDEX graph_idx_instance_id (instance_id),
                  ADD CONSTRAINT graph_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE layout ADD COLUMN instance_id integer NULL,
                   ADD COLUMN link_parent integer NULL,
                   ADD INDEX layout_idx_instance_id (instance_id),
                   ADD INDEX layout_idx_link_parent (link_parent),
                   ADD CONSTRAINT layout_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION,
                   ADD CONSTRAINT layout_fk_link_parent FOREIGN KEY (link_parent) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE metric_group ADD COLUMN instance_id integer NULL,
                         ADD INDEX metric_group_idx_instance_id (instance_id),
                         ADD CONSTRAINT metric_group_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE view ADD COLUMN instance_id integer NULL,
                 ADD INDEX view_idx_instance_id (instance_id),
                 ADD CONSTRAINT view_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

