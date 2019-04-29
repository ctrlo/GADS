-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/66/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "team" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "site_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "team_idx_site_id" on "team" ("site_id");

;
ALTER TABLE "team" ADD CONSTRAINT "team_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE site ADD COLUMN register_team_help text;

;
ALTER TABLE site ADD COLUMN register_team_name text;

;
ALTER TABLE site ADD COLUMN register_show_team smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "user" ADD COLUMN team_id integer;

;
CREATE INDEX user_idx_team_id on "user" (team_id);

;
ALTER TABLE "user" ADD CONSTRAINT user_fk_team_id FOREIGN KEY (team_id)
  REFERENCES team (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

