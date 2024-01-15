-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
DROP TABLE alert CASCADE;

;
DROP TABLE alert_cache CASCADE;

;
DROP TABLE alert_column CASCADE;

;
DROP TABLE alert_send CASCADE;

;
DROP TABLE audit CASCADE;

;
DROP TABLE authentication CASCADE;

;
DROP TABLE calc CASCADE;

;
DROP TABLE calcval CASCADE;

;
DROP TABLE current CASCADE;

;
DROP TABLE curval CASCADE;

;
DROP TABLE curval_fields CASCADE;

;
DROP TABLE dashboard CASCADE;

;
DROP TABLE date CASCADE;

;
DROP TABLE daterange CASCADE;

;
DROP TABLE department CASCADE;

;
DROP TABLE display_field CASCADE;

;
DROP TABLE enum CASCADE;

;
DROP TABLE enumval CASCADE;

;
DROP TABLE export CASCADE;

;
DROP TABLE file CASCADE;

;
DROP TABLE file_option CASCADE;

;
DROP TABLE fileval CASCADE;

;
DROP TABLE filter CASCADE;

;
DROP TABLE filtered_value CASCADE;

;
DROP TABLE graph CASCADE;

;
DROP TABLE graph_color CASCADE;

;
DROP TABLE group CASCADE;

;
DROP TABLE import CASCADE;

;
DROP TABLE import_row CASCADE;

;
DROP TABLE instance CASCADE;

;
DROP TABLE instance_group CASCADE;

;
DROP TABLE instance_rag CASCADE;

;
DROP TABLE intgr CASCADE;

;
DROP TABLE layout CASCADE;

;
DROP TABLE layout_depend CASCADE;

;
DROP TABLE layout_group CASCADE;

;
DROP TABLE metric CASCADE;

;
DROP TABLE metric_group CASCADE;

;
DROP TABLE oauthclient CASCADE;

;
DROP TABLE oauthtoken CASCADE;

;
DROP TABLE organisation CASCADE;

;
DROP TABLE permission CASCADE;

;
DROP TABLE person CASCADE;

;
DROP TABLE rag CASCADE;

;
DROP TABLE ragval CASCADE;

;
DROP TABLE record CASCADE;

;
DROP TABLE report CASCADE;

;
DROP TABLE report_layout CASCADE;

;
DROP TABLE site CASCADE;

;
DROP TABLE sort CASCADE;

;
DROP TABLE string CASCADE;

;
DROP TABLE submission CASCADE;

;
DROP TABLE team CASCADE;

;
DROP TABLE title CASCADE;

;
DROP TABLE topic CASCADE;

;
DROP TABLE user CASCADE;

;
DROP TABLE user_graph CASCADE;

;
DROP TABLE user_group CASCADE;

;
DROP TABLE user_lastrecord CASCADE;

;
DROP TABLE user_permission CASCADE;

;
DROP TABLE view CASCADE;

;
DROP TABLE view_group CASCADE;

;
DROP TABLE view_layout CASCADE;

;
DROP TABLE view_limit CASCADE;

;
DROP TABLE widget CASCADE;

;

COMMIT;

