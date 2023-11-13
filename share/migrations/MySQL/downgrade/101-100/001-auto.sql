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
ALTER TABLE report_layout DROP FOREIGN KEY report_layout_fk_layout_id,
                          DROP FOREIGN KEY report_layout_fk_report_id;

;
DROP TABLE report_layout;

;

COMMIT;

