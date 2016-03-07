-- Convert schema '/root/GADS/share/migrations/_source/deploy/5/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "user_lastrecord" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "instance_id" integer NOT NULL,
  "user_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_lastrecord_idx_instance_id" on "user_lastrecord" ("instance_id");
CREATE INDEX "user_lastrecord_idx_record_id" on "user_lastrecord" ("record_id");
CREATE INDEX "user_lastrecord_idx_user_id" on "user_lastrecord" ("user_id");

;
ALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

