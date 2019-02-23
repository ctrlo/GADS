-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/61/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/62/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE submission DROP CONSTRAINT ux_submission_token;

;
ALTER TABLE submission ADD CONSTRAINT ux_submission_token UNIQUE (token, submitted);

;

COMMIT;

