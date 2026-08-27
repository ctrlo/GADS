-- Convert schema '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml' to '/home/abeverley/git/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site DROP COLUMN force_mfa;

;
ALTER TABLE user DROP COLUMN mfa_type,
                 DROP COLUMN mobile,
                 DROP COLUMN mobile_verified,
                 DROP COLUMN mfa_secret,
                 DROP COLUMN mfa_sms_token,
                 DROP COLUMN mfa_sms_created,
                 DROP COLUMN mfa_token_previous,
                 DROP COLUMN mfa_token_previous_type,
                 DROP COLUMN mfa_token_previous_used,
                 DROP COLUMN mfa_token_previous_key,
                 DROP COLUMN mfa_lastfail,
                 DROP COLUMN mfa_failcount;

;

COMMIT;

