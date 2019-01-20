-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/57/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/58/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "department" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "site_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "department_idx_site_id" on "department" ("site_id");

;
ALTER TABLE "department" ADD CONSTRAINT "department_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE site ADD COLUMN register_department_help text;

;
ALTER TABLE site ADD COLUMN register_department_name text;

;
ALTER TABLE site ADD COLUMN register_show_department smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "user" ADD COLUMN department_id integer;

;
CREATE INDEX user_idx_department_id on "user" (department_id);

;
ALTER TABLE "user" ADD CONSTRAINT user_fk_department_id FOREIGN KEY (department_id)
  REFERENCES department (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

