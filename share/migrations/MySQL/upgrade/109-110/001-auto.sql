-- Convert schema '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/109/001-auto.yml' to '/home/droberts/source/gads3/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE authentication ADD COLUMN cacert text NULL,
                           ADD COLUMN sp_cert text NULL,
                           ADD COLUMN sp_key text NULL,
                           ADD COLUMN saml2_groupname text NULL,
                           ADD COLUMN saml2_relaystate varchar(80) NULL,
                           ADD COLUMN saml2_unique_id varchar(80) NULL,
                           ADD COLUMN saml2_nameid varchar(30) NULL,
                           CHANGE COLUMN type type varchar(255) NOT NULL DEFAULT '1',
                           ADD UNIQUE authentication_ux_saml2_relaystate (saml2_relaystate),
                           ADD UNIQUE authentication_ux_saml2_unique_id (saml2_unique_id);

;
ALTER TABLE site ADD COLUMN register_show_provider smallint NOT NULL DEFAULT 0;

;
ALTER TABLE user ADD COLUMN provider integer NULL,
                 ADD INDEX user_idx_provider (provider),
                 ADD CONSTRAINT user_fk_provider FOREIGN KEY (provider) REFERENCES authentication (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

