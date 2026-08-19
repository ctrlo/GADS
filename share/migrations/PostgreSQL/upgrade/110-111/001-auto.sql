-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN force_mfa character(3);

;
ALTER TABLE "user" ADD COLUMN mfa_type character(3);

;
ALTER TABLE "user" ADD COLUMN mobile text;

;
ALTER TABLE "user" ADD COLUMN mobile_verified smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE "user" ADD COLUMN mfa_secret text;

;
ALTER TABLE "user" ADD COLUMN mfa_sms_token text;

;
ALTER TABLE "user" ADD COLUMN mfa_sms_created timestamp;

;
ALTER TABLE "user" ADD COLUMN mfa_token_previous text;

;
ALTER TABLE "user" ADD COLUMN mfa_token_previous_type character(3);

;
ALTER TABLE "user" ADD COLUMN mfa_token_previous_used timestamp;

;
ALTER TABLE "user" ADD COLUMN mfa_token_previous_key text;

;
ALTER TABLE "user" ADD COLUMN mfa_lastfail timestamp;

;
ALTER TABLE "user" ADD COLUMN mfa_failcount integer DEFAULT 0 NOT NULL;

;

COMMIT;

