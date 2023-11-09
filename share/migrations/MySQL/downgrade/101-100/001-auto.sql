-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/101/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/100/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report DROP FOREIGN KEY report_fk_createdby,
                   DROP FOREIGN KEY report_fk_instance_id,
                   DROP FOREIGN KEY report_fk_user_id;

;
DROP TABLE report;

;
ALTER TABLE report_instance DROP FOREIGN KEY report_instance_fk_layout_id,
                            DROP FOREIGN KEY report_instance_fk_report_id;

;
DROP TABLE report_instance;

;

COMMIT;

