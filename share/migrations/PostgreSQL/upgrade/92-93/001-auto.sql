-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/92/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/93/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "instance_rag" (
  "id" serial NOT NULL,
  "instance_id" integer NOT NULL,
  "rag" character varying(16) NOT NULL,
  "enabled" smallint DEFAULT 0 NOT NULL,
  "description" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "instance_rag_ux_instance_rag" UNIQUE ("instance_id", "rag")
);
CREATE INDEX "instance_rag_idx_instance_id" on "instance_rag" ("instance_id");

;
ALTER TABLE "instance_rag" ADD CONSTRAINT "instance_rag_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

