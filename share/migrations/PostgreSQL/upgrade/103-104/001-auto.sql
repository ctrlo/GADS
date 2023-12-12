-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/103/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "report_defaults" (
  "id" bigserial NOT NULL,
  "name" character varying(128) NOT NULL,
  "value" character varying(128),
  "data" bytea,
  "type" character varying(128),
  PRIMARY KEY ("id")
);
CREATE INDEX "name_idx" on "report_defaults" ("name");

;
ALTER TABLE report ADD COLUMN title character varying(128);

;
ALTER TABLE report ADD COLUMN security_marking character varying(128);

;
ALTER TABLE report ADD COLUMN security_marking_extra character varying(128);

;

COMMIT;

