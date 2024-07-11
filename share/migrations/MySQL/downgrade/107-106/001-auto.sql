-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE report_group DROP FOREIGN KEY report_group_fk_group_id,
                         DROP FOREIGN KEY report_group_fk_report_id;

;
DROP TABLE report_group;

;

COMMIT;

