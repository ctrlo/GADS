-- Convert schema 'share/migrations/_source/deploy/105/001-auto.yml' to 'share/migrations/_source/deploy/106/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "calc_unique" (
  "id" bigserial NOT NULL,
  "layout_id" integer NOT NULL,
  "value_text" text,
  "value_int" bigint,
  "value_date" date,
  "value_numeric" numeric(20,5),
  "value_date_from" timestamp,
  "value_date_to" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "calc_unique_ux_layout_date" UNIQUE ("layout_id", "value_date"),
  CONSTRAINT "calc_unique_ux_layout_daterange" UNIQUE ("layout_id", "value_date_from", "value_date_to"),
  CONSTRAINT "calc_unique_ux_layout_int" UNIQUE ("layout_id", "value_int"),
  CONSTRAINT "calc_unique_ux_layout_numeric" UNIQUE ("layout_id", "value_numeric"),
  CONSTRAINT "calc_unique_ux_layout_text" UNIQUE ("layout_id", "value_text")
);
CREATE INDEX "calc_unique_idx_layout_id" on "calc_unique" ("layout_id");

;
ALTER TABLE "calc_unique" ADD CONSTRAINT "calc_unique_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

