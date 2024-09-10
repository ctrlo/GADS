-- Convert schema '/home/droberts/source/gads2/bin/../share/migrations/_source/deploy/107/001-auto.yml' to '/home/droberts/source/gads2/bin/../share/migrations/_source/deploy/108/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "report_group" (
  "id" serial NOT NULL,
  "report_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_group_idx_group_id" on "report_group" ("group_id");
CREATE INDEX "report_group_idx_report_id" on "report_group" ("report_id");

;
ALTER TABLE "report_group" ADD CONSTRAINT "report_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_group" ADD CONSTRAINT "report_group_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

