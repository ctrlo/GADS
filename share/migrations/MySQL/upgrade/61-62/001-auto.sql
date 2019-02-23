-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/61/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/62/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE submission DROP INDEX ux_submission_token,
                       ADD UNIQUE ux_submission_token (token, submitted);

;

COMMIT;

