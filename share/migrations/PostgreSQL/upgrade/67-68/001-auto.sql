-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/68/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "display_field" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "display_field_id" integer NOT NULL,
  "regex" text,
  "operator" character varying(16),
  PRIMARY KEY ("id")
);
CREATE INDEX "display_field_idx_display_field_id" on "display_field" ("display_field_id");
CREATE INDEX "display_field_idx_layout_id" on "display_field" ("layout_id");

;
ALTER TABLE "display_field" ADD CONSTRAINT "display_field_fk_display_field_id" FOREIGN KEY ("display_field_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "display_field" ADD CONSTRAINT "display_field_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE layout ADD COLUMN display_condition character(3);

;

COMMIT;

