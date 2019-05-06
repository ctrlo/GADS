-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/69/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/70/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "view_group" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "layout_id" integer,
  "parent_id" integer,
  "order" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_group_idx_layout_id" on "view_group" ("layout_id");
CREATE INDEX "view_group_idx_parent_id" on "view_group" ("parent_id");
CREATE INDEX "view_group_idx_view_id" on "view_group" ("view_id");

;
ALTER TABLE "view_group" ADD CONSTRAINT "view_group_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_group" ADD CONSTRAINT "view_group_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_group" ADD CONSTRAINT "view_group_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE sort ADD COLUMN "order" integer;

;
CREATE INDEX sort_idx_layout_id on sort (layout_id);

;
ALTER TABLE sort ADD CONSTRAINT sort_fk_layout_id FOREIGN KEY (layout_id)
  REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

