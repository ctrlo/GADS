-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/56/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/57/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "submission" (
  "id" serial NOT NULL,
  "token" character varying(64) NOT NULL,
  "created" timestamp,
  "submitted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "ux_submission_token" UNIQUE ("token")
);

;

COMMIT;

