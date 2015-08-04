-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/1/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "graph_color" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "color" character(6),
  PRIMARY KEY ("id"),
  CONSTRAINT "ux_graph_color_name" UNIQUE ("name")
);

;
ALTER TABLE current ADD COLUMN parent_id integer;

;
ALTER TABLE current ADD COLUMN linked_id integer;

;
CREATE INDEX current_idx_linked_id on current (linked_id);

;
CREATE INDEX current_idx_parent_id on current (parent_id);

;
ALTER TABLE current ADD CONSTRAINT current_fk_linked_id FOREIGN KEY (linked_id)
  REFERENCES current (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE current ADD CONSTRAINT current_fk_parent_id FOREIGN KEY (parent_id)
  REFERENCES current (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE graph ADD COLUMN instance_id integer;

;
CREATE INDEX graph_idx_instance_id on graph (instance_id);

;
ALTER TABLE graph ADD CONSTRAINT graph_fk_instance_id FOREIGN KEY (instance_id)
  REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE layout ADD COLUMN instance_id integer;

;
ALTER TABLE layout ADD COLUMN link_parent integer;

;
CREATE INDEX layout_idx_instance_id on layout (instance_id);

;
CREATE INDEX layout_idx_link_parent on layout (link_parent);

;
ALTER TABLE layout ADD CONSTRAINT layout_fk_instance_id FOREIGN KEY (instance_id)
  REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE layout ADD CONSTRAINT layout_fk_link_parent FOREIGN KEY (link_parent)
  REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE metric_group ADD COLUMN instance_id integer;

;
CREATE INDEX metric_group_idx_instance_id on metric_group (instance_id);

;
ALTER TABLE metric_group ADD CONSTRAINT metric_group_fk_instance_id FOREIGN KEY (instance_id)
  REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE view ADD COLUMN instance_id integer;

;
CREATE INDEX view_idx_instance_id on view (instance_id);

;
ALTER TABLE view ADD CONSTRAINT view_fk_instance_id FOREIGN KEY (instance_id)
  REFERENCES instance (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

