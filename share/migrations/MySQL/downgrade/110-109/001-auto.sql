-- Convert schema '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/110/001-auto.yml' to '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/109/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE authentication DROP CONSTRAINT authentication_ux_saml2_relaystate,
                           DROP CONSTRAINT authentication_ux_saml2_unique_id,
                           DROP COLUMN cacert,
                           DROP COLUMN sp_cert,
                           DROP COLUMN sp_key,
                           DROP COLUMN saml2_groupname,
                           DROP COLUMN saml2_relaystate,
                           DROP COLUMN saml2_unique_id,
                           DROP COLUMN saml2_nameid,
                           CHANGE COLUMN type type varchar(32) NULL;

;
ALTER TABLE site DROP COLUMN register_show_provider;

;
ALTER TABLE user DROP FOREIGN KEY user_fk_provider,
                 DROP INDEX user_idx_provider,
                 DROP COLUMN provider;

;

COMMIT;

