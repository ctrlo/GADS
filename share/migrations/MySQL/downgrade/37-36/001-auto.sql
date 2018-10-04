-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/37/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
DROP TABLE oauthclient;

;
ALTER TABLE oauthtoken DROP FOREIGN KEY oauthtoken_fk_oauthclient_id,
                       DROP FOREIGN KEY oauthtoken_fk_user_id;

;
DROP TABLE oauthtoken;

;

COMMIT;

