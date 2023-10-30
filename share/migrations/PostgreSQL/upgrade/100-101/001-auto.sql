-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/100/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/101/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "report" (
  "id" bigserial NOT NULL,
  "name" character varying(128) NOT NULL,
  "description" character varying(128),
  "user_id" bigint,
  "createdby" bigint,
  "created" timestamp,
  "instance_id" bigint,
  "deleted" smallint,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_idx_createdby" on "report" ("createdby");
CREATE INDEX "report_idx_instance_id" on "report" ("instance_id");
CREATE INDEX "report_idx_user_id" on "report" ("user_id");

;
CREATE TABLE "report_instance" (
  "id" serial NOT NULL,
  "report_id" integer NOT NULL,
  "layout_id" bigint NOT NULL,
  "order" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_instance_idx_layout_id" on "report_instance" ("layout_id");
CREATE INDEX "report_instance_idx_report_id" on "report_instance" ("report_id");

;
ALTER TABLE "report" ADD CONSTRAINT "report_fk_createdby" FOREIGN KEY ("createdby")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report" ADD CONSTRAINT "report_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report" ADD CONSTRAINT "report_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_instance" ADD CONSTRAINT "report_instance_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_instance" ADD CONSTRAINT "report_instance_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

