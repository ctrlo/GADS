-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/89/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/90/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "export" (
  "id" serial NOT NULL,
  "site_id" integer,
  "user_id" bigint NOT NULL,
  "type" character varying(45),
  "started" timestamp,
  "completed" timestamp,
  "result" text,
  "mimetype" text,
  "content" bytea,
  PRIMARY KEY ("id")
);
CREATE INDEX "export_idx_site_id" on "export" ("site_id");
CREATE INDEX "export_idx_user_id" on "export" ("user_id");

;
ALTER TABLE "export" ADD CONSTRAINT "export_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "export" ADD CONSTRAINT "export_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

