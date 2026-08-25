-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "file_option" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "filesize" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "file_option_idx_layout_id" on "file_option" ("layout_id");

;
ALTER TABLE "file_option" ADD CONSTRAINT "file_option_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

