-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/82/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "alert_column" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "instance_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "alert_column_idx_instance_id" on "alert_column" ("instance_id");
CREATE INDEX "alert_column_idx_layout_id" on "alert_column" ("layout_id");

;
ALTER TABLE "alert_column" ADD CONSTRAINT "alert_column_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_column" ADD CONSTRAINT "alert_column_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

