-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/25/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "view_limit" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_limit_idx_user_id" on "view_limit" ("user_id");
CREATE INDEX "view_limit_idx_view_id" on "view_limit" ("view_id");

;
ALTER TABLE "view_limit" ADD CONSTRAINT "view_limit_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_limit" ADD CONSTRAINT "view_limit_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

