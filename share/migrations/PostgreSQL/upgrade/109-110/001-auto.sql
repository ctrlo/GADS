-- Convert schema '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/109/001-auto.yml' to '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "authentication" ADD COLUMN cacert text;

;
ALTER TABLE "authentication" ADD COLUMN sp_cert text;

;
ALTER TABLE "authentication" ADD COLUMN sp_key text;

;
ALTER TABLE "authentication" ADD COLUMN saml2_groupname text;

;
ALTER TABLE "authentication" ADD COLUMN saml2_relaystate character varying(80);

;
ALTER TABLE "authentication" ADD COLUMN saml2_unique_id character varying(80);

;
ALTER TABLE "authentication" ADD COLUMN saml2_nameid character varying(30);

;
ALTER TABLE "authentication" ALTER COLUMN type SET NOT NULL;

;
ALTER TABLE "authentication" ALTER COLUMN type TYPE character varying;

;
ALTER TABLE "authentication" ALTER COLUMN type SET DEFAULT '1';

;
ALTER TABLE "authentication" ADD CONSTRAINT authentication_ux_saml2_relaystate UNIQUE (saml2_relaystate);

;
ALTER TABLE "authentication" ADD CONSTRAINT authentication_ux_saml2_unique_id UNIQUE (saml2_unique_id);

;
ALTER TABLE "site" ADD COLUMN register_show_provider smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "user" ADD COLUMN provider integer;

;
CREATE INDEX user_idx_provider on "user" (provider);

;
ALTER TABLE "user" ADD CONSTRAINT user_fk_provider FOREIGN KEY (provider)
  REFERENCES "authentication" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

