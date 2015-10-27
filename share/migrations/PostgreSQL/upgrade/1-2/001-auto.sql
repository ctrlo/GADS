-- Convert schema '/root/GADS/share/migrations/_source/deploy/1/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "curval" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "value" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "curval_idx_layout_id" on "curval" ("layout_id");
CREATE INDEX "curval_idx_record_id" on "curval" ("record_id");
CREATE INDEX "curval_idx_value" on "curval" ("value");

;
CREATE TABLE "curval_fields" (
  "id" serial NOT NULL,
  "parent_id" integer NOT NULL,
  "child_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "curval_fields_idx_child_id" on "curval_fields" ("child_id");
CREATE INDEX "curval_fields_idx_parent_id" on "curval_fields" ("parent_id");

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_value" FOREIGN KEY ("value")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval_fields" ADD CONSTRAINT "curval_fields_fk_child_id" FOREIGN KEY ("child_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval_fields" ADD CONSTRAINT "curval_fields_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE calcval ADD COLUMN value_text citext;

;
ALTER TABLE calcval ADD COLUMN value_int bigint;

;
ALTER TABLE calcval ADD COLUMN value_date date;

;
ALTER TABLE instance ALTER COLUMN name TYPE text;

;
ALTER TABLE layout DROP COLUMN hidden;

;
ALTER TABLE "user" ADD COLUMN limit_to_view bigint;

;
CREATE INDEX user_idx_limit_to_view on "user" (limit_to_view);

;
CREATE INDEX user_idx_email on "user" (email);

;
CREATE INDEX user_idx_username on "user" (username);

;
ALTER TABLE "user" ADD CONSTRAINT user_fk_limit_to_view FOREIGN KEY (limit_to_view)
  REFERENCES view (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

