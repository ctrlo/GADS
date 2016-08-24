-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/15/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "import" (
  "id" serial NOT NULL,
  "user_id" bigint NOT NULL,
  "type" character varying(45),
  "row_count" integer DEFAULT 0 NOT NULL,
  "started" timestamp,
  "completed" timestamp,
  "written_count" integer DEFAULT 0 NOT NULL,
  "error_count" integer DEFAULT 0 NOT NULL,
  "skipped_count" integer DEFAULT 0 NOT NULL,
  "result" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_idx_user_id" on "import" ("user_id");

;
CREATE TABLE "import_row" (
  "id" bigserial NOT NULL,
  "import_id" integer NOT NULL,
  "status" character varying(45),
  "content" text,
  "errors" text,
  "changes" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_row_idx_import_id" on "import_row" ("import_id");

;
ALTER TABLE "import" ADD CONSTRAINT "import_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import_row" ADD CONSTRAINT "import_row_fk_import_id" FOREIGN KEY ("import_id")
  REFERENCES "import" ("id") ON DELETE CASCADE ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

