-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/44/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/45/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "topic" (
  "id" serial NOT NULL,
  "instance_id" integer,
  "name" text,
  "initial_state" character varying(32),
  "click_to_edit" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "topic_idx_instance_id" on "topic" ("instance_id");

;
ALTER TABLE "topic" ADD CONSTRAINT "topic_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE layout ADD COLUMN topic_id integer;

;
CREATE INDEX layout_idx_topic_id on layout (topic_id);

;
ALTER TABLE layout ADD CONSTRAINT layout_fk_topic_id FOREIGN KEY (topic_id)
  REFERENCES topic (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

