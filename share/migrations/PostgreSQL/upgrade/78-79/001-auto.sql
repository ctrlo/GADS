-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/78/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/79/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "filtered_value" (
  "id" serial NOT NULL,
  "submission_id" integer,
  "layout_id" integer,
  "current_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "filtered_value_idx_current_id" on "filtered_value" ("current_id");
CREATE INDEX "filtered_value_idx_layout_id" on "filtered_value" ("layout_id");
CREATE INDEX "filtered_value_idx_submission_id" on "filtered_value" ("submission_id");

;
ALTER TABLE "filtered_value" ADD CONSTRAINT "filtered_value_fk_current_id" FOREIGN KEY ("current_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filtered_value" ADD CONSTRAINT "filtered_value_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filtered_value" ADD CONSTRAINT "filtered_value_fk_submission_id" FOREIGN KEY ("submission_id")
  REFERENCES "submission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

