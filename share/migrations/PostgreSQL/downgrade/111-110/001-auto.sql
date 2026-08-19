-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN force_mfa;

;
ALTER TABLE "user" DROP COLUMN mfa_type;

;
ALTER TABLE "user" DROP COLUMN mobile;

;
ALTER TABLE "user" DROP COLUMN mobile_verified;

;
ALTER TABLE "user" DROP COLUMN mfa_secret;

;
ALTER TABLE "user" DROP COLUMN mfa_sms_token;

;
ALTER TABLE "user" DROP COLUMN mfa_sms_created;

;
ALTER TABLE "user" DROP COLUMN mfa_token_previous;

;
ALTER TABLE "user" DROP COLUMN mfa_token_previous_type;

;
ALTER TABLE "user" DROP COLUMN mfa_token_previous_used;

;
ALTER TABLE "user" DROP COLUMN mfa_token_previous_key;

;
ALTER TABLE "user" DROP COLUMN mfa_lastfail;

;
ALTER TABLE "user" DROP COLUMN mfa_failcount;

;

COMMIT;

