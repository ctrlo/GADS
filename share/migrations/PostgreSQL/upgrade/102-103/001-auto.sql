-- Convert schema 'share/migrations/_source/deploy/102/001-auto.yml' to 'share/migrations/_source/deploy/103/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX audit_idx_user_instance_datetime on audit (user_id, instance_id, datetime);

;

COMMIT;

