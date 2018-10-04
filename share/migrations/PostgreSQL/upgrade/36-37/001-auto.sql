-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/36/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/37/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "oauthclient" (
  "id" bigserial NOT NULL,
  "client_id" character varying(64) NOT NULL,
  "client_secret" character varying(64) NOT NULL,
  PRIMARY KEY ("id")
);

;
CREATE TABLE "oauthtoken" (
  "token" character varying(128) NOT NULL,
  "related_token" character varying(128) NOT NULL,
  "oauthclient_id" integer NOT NULL,
  "user_id" bigint NOT NULL,
  "type" character varying(12) NOT NULL,
  "expires" integer,
  PRIMARY KEY ("token")
);
CREATE INDEX "oauthtoken_idx_oauthclient_id" on "oauthtoken" ("oauthclient_id");
CREATE INDEX "oauthtoken_idx_user_id" on "oauthtoken" ("user_id");

;
ALTER TABLE "oauthtoken" ADD CONSTRAINT "oauthtoken_fk_oauthclient_id" FOREIGN KEY ("oauthclient_id")
  REFERENCES "oauthclient" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "oauthtoken" ADD CONSTRAINT "oauthtoken_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

