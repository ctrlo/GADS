-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "instance_group" (
  "id" serial NOT NULL,
  "instance_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "permission" character varying(45) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "instance_group_ux_instance_group_permission" UNIQUE ("instance_id", "group_id", "permission")
);
CREATE INDEX "instance_group_idx_group_id" on "instance_group" ("group_id");
CREATE INDEX "instance_group_idx_instance_id" on "instance_group" ("instance_id");

;
ALTER TABLE "instance_group" ADD CONSTRAINT "instance_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance_group" ADD CONSTRAINT "instance_group_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

