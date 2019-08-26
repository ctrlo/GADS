-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/72/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/73/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "dashboard" (
  "id" serial NOT NULL,
  "instance_id" integer,
  "user_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "dashboard_idx_instance_id" on "dashboard" ("instance_id");
CREATE INDEX "dashboard_idx_user_id" on "dashboard" ("user_id");

;
CREATE TABLE "widget" (
  "id" serial NOT NULL,
  "grid_id" character varying(64),
  "dashboard_id" integer,
  "type" character varying(16),
  "static" smallint DEFAULT 0 NOT NULL,
  "h" smallint DEFAULT 0,
  "w" smallint DEFAULT 0,
  "x" smallint DEFAULT 0,
  "y" smallint DEFAULT 0,
  "content" text,
  "view_id" integer,
  "graph_id" integer,
  "rows" integer,
  "tl_options" text,
  "globe_options" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "widget_ux_dashboard_grid" UNIQUE ("dashboard_id", "grid_id")
);
CREATE INDEX "widget_idx_dashboard_id" on "widget" ("dashboard_id");
CREATE INDEX "widget_idx_graph_id" on "widget" ("graph_id");
CREATE INDEX "widget_idx_view_id" on "widget" ("view_id");

;
ALTER TABLE "dashboard" ADD CONSTRAINT "dashboard_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "dashboard" ADD CONSTRAINT "dashboard_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "widget" ADD CONSTRAINT "widget_fk_dashboard_id" FOREIGN KEY ("dashboard_id")
  REFERENCES "dashboard" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "widget" ADD CONSTRAINT "widget_fk_graph_id" FOREIGN KEY ("graph_id")
  REFERENCES "graph" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "widget" ADD CONSTRAINT "widget_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

