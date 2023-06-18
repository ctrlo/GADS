-- Convert schema 'share/migrations/_source/deploy/99/001-auto.yml' to 'share/migrations/_source/deploy/98/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE audit DROP INDEX audit_idx_datetime;

;

COMMIT;

