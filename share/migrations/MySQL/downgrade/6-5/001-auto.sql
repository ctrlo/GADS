-- Convert schema '/root/GADS/share/migrations/_source/deploy/6/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE user_lastrecord DROP FOREIGN KEY user_lastrecord_fk_instance_id,
                            DROP FOREIGN KEY user_lastrecord_fk_record_id,
                            DROP FOREIGN KEY user_lastrecord_fk_user_id;

;
DROP TABLE user_lastrecord;

;

COMMIT;

