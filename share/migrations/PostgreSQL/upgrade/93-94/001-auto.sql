-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/93/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/94/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "authentication" (
  "id" bigserial NOT NULL,
  "site_id" integer,
  "type" character varying(32),
  "name" text,
  "xml" text,
  "saml2_firstname" text,
  "saml2_surname" text,
  "enabled" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "authentication_idx_site_id" on "authentication" ("site_id");

;
ALTER TABLE "authentication" ADD CONSTRAINT "authentication_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

