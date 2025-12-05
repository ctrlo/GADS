-- Convert schema '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/110/001-auto.yml' to '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/109/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "authentication" DROP CONSTRAINT authentication_ux_saml2_relaystate;

;
ALTER TABLE "authentication" DROP CONSTRAINT authentication_ux_saml2_unique_id;

;
ALTER TABLE "authentication" DROP COLUMN cacert;

;
ALTER TABLE "authentication" DROP COLUMN sp_cert;

;
ALTER TABLE "authentication" DROP COLUMN sp_key;

;
ALTER TABLE "authentication" DROP COLUMN saml2_groupname;

;
ALTER TABLE "authentication" DROP COLUMN saml2_relaystate;

;
ALTER TABLE "authentication" DROP COLUMN saml2_unique_id;

;
ALTER TABLE "authentication" DROP COLUMN saml2_nameid;

;
ALTER TABLE "authentication" ALTER COLUMN type DROP NOT NULL;

;
ALTER TABLE "authentication" ALTER COLUMN type TYPE character varying(32);

;
ALTER TABLE "authentication" ALTER COLUMN type DROP DEFAULT;

;
ALTER TABLE "site" DROP COLUMN register_show_provider;

;
ALTER TABLE "user" DROP CONSTRAINT user_fk_provider;

;
DROP INDEX user_idx_provider;

;
ALTER TABLE "user" DROP COLUMN provider;

;

COMMIT;

