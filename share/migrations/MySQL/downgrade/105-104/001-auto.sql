-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE alert DROP FOREIGN KEY alert_fk_user_id,
                  DROP FOREIGN KEY alert_fk_view_id;

;
DROP TABLE alert;

;
ALTER TABLE alert_cache DROP FOREIGN KEY alert_cache_fk_current_id,
                        DROP FOREIGN KEY alert_cache_fk_layout_id,
                        DROP FOREIGN KEY alert_cache_fk_user_id,
                        DROP FOREIGN KEY alert_cache_fk_view_id;

;
DROP TABLE alert_cache;

;
ALTER TABLE alert_column DROP FOREIGN KEY alert_column_fk_instance_id,
                         DROP FOREIGN KEY alert_column_fk_layout_id;

;
DROP TABLE alert_column;

;
ALTER TABLE alert_send DROP FOREIGN KEY alert_send_fk_alert_id,
                       DROP FOREIGN KEY alert_send_fk_current_id,
                       DROP FOREIGN KEY alert_send_fk_layout_id;

;
DROP TABLE alert_send;

;
ALTER TABLE audit DROP FOREIGN KEY audit_fk_instance_id,
                  DROP FOREIGN KEY audit_fk_site_id,
                  DROP FOREIGN KEY audit_fk_user_id;

;
DROP TABLE audit;

;
ALTER TABLE authentication DROP FOREIGN KEY authentication_fk_site_id;

;
DROP TABLE authentication;

;
ALTER TABLE calc DROP FOREIGN KEY calc_fk_layout_id;

;
DROP TABLE calc;

;
ALTER TABLE calcval DROP FOREIGN KEY calcval_fk_layout_id,
                    DROP FOREIGN KEY calcval_fk_record_id;

;
DROP TABLE calcval;

;
ALTER TABLE current DROP FOREIGN KEY current_fk_deletedby,
                    DROP FOREIGN KEY current_fk_draftuser_id,
                    DROP FOREIGN KEY current_fk_instance_id,
                    DROP FOREIGN KEY current_fk_linked_id,
                    DROP FOREIGN KEY current_fk_parent_id;

;
DROP TABLE current;

;
ALTER TABLE curval DROP FOREIGN KEY curval_fk_layout_id,
                   DROP FOREIGN KEY curval_fk_record_id,
                   DROP FOREIGN KEY curval_fk_value;

;
DROP TABLE curval;

;
ALTER TABLE curval_fields DROP FOREIGN KEY curval_fields_fk_child_id,
                          DROP FOREIGN KEY curval_fields_fk_parent_id;

;
DROP TABLE curval_fields;

;
ALTER TABLE dashboard DROP FOREIGN KEY dashboard_fk_instance_id,
                      DROP FOREIGN KEY dashboard_fk_site_id,
                      DROP FOREIGN KEY dashboard_fk_user_id;

;
DROP TABLE dashboard;

;
ALTER TABLE date DROP FOREIGN KEY date_fk_layout_id,
                 DROP FOREIGN KEY date_fk_record_id;

;
DROP TABLE date;

;
ALTER TABLE daterange DROP FOREIGN KEY daterange_fk_layout_id,
                      DROP FOREIGN KEY daterange_fk_record_id;

;
DROP TABLE daterange;

;
ALTER TABLE department DROP FOREIGN KEY department_fk_site_id;

;
DROP TABLE department;

;
ALTER TABLE display_field DROP FOREIGN KEY display_field_fk_display_field_id,
                          DROP FOREIGN KEY display_field_fk_layout_id;

;
DROP TABLE display_field;

;
ALTER TABLE enum DROP FOREIGN KEY enum_fk_layout_id,
                 DROP FOREIGN KEY enum_fk_record_id,
                 DROP FOREIGN KEY enum_fk_value;

;
DROP TABLE enum;

;
ALTER TABLE enumval DROP FOREIGN KEY enumval_fk_layout_id,
                    DROP FOREIGN KEY enumval_fk_parent;

;
DROP TABLE enumval;

;
ALTER TABLE export DROP FOREIGN KEY export_fk_site_id,
                   DROP FOREIGN KEY export_fk_user_id;

;
DROP TABLE export;

;
ALTER TABLE file DROP FOREIGN KEY file_fk_layout_id,
                 DROP FOREIGN KEY file_fk_record_id,
                 DROP FOREIGN KEY file_fk_value;

;
DROP TABLE file;

;
ALTER TABLE file_option DROP FOREIGN KEY file_option_fk_layout_id;

;
DROP TABLE file_option;

;
ALTER TABLE fileval DROP FOREIGN KEY fileval_fk_edit_user_id;

;
DROP TABLE fileval;

;
ALTER TABLE filter DROP FOREIGN KEY filter_fk_layout_id,
                   DROP FOREIGN KEY filter_fk_view_id;

;
DROP TABLE filter;

;
ALTER TABLE filtered_value DROP FOREIGN KEY filtered_value_fk_current_id,
                           DROP FOREIGN KEY filtered_value_fk_layout_id,
                           DROP FOREIGN KEY filtered_value_fk_submission_id;

;
DROP TABLE filtered_value;

;
ALTER TABLE graph DROP FOREIGN KEY graph_fk_group_id,
                  DROP FOREIGN KEY graph_fk_group_by,
                  DROP FOREIGN KEY graph_fk_instance_id,
                  DROP FOREIGN KEY graph_fk_metric_group,
                  DROP FOREIGN KEY graph_fk_user_id,
                  DROP FOREIGN KEY graph_fk_x_axis,
                  DROP FOREIGN KEY graph_fk_x_axis_link,
                  DROP FOREIGN KEY graph_fk_y_axis;

;
DROP TABLE graph;

;
DROP TABLE graph_color;

;
ALTER TABLE group DROP FOREIGN KEY group_fk_site_id;

;
DROP TABLE group;

;
ALTER TABLE import DROP FOREIGN KEY import_fk_instance_id,
                   DROP FOREIGN KEY import_fk_site_id,
                   DROP FOREIGN KEY import_fk_user_id;

;
DROP TABLE import;

;
ALTER TABLE import_row DROP FOREIGN KEY import_row_fk_import_id;

;
DROP TABLE import_row;

;
ALTER TABLE instance DROP FOREIGN KEY instance_fk_api_index_layout_id,
                     DROP FOREIGN KEY instance_fk_default_view_limit_extra_id,
                     DROP FOREIGN KEY instance_fk_site_id,
                     DROP FOREIGN KEY instance_fk_sort_layout_id,
                     DROP FOREIGN KEY instance_fk_view_limit_id;

;
DROP TABLE instance;

;
ALTER TABLE instance_group DROP FOREIGN KEY instance_group_fk_group_id,
                           DROP FOREIGN KEY instance_group_fk_instance_id;

;
DROP TABLE instance_group;

;
ALTER TABLE instance_rag DROP FOREIGN KEY instance_rag_fk_instance_id;

;
DROP TABLE instance_rag;

;
ALTER TABLE intgr DROP FOREIGN KEY intgr_fk_layout_id,
                  DROP FOREIGN KEY intgr_fk_record_id;

;
DROP TABLE intgr;

;
ALTER TABLE layout DROP FOREIGN KEY layout_fk_display_field,
                   DROP FOREIGN KEY layout_fk_instance_id,
                   DROP FOREIGN KEY layout_fk_link_parent,
                   DROP FOREIGN KEY layout_fk_related_field,
                   DROP FOREIGN KEY layout_fk_topic_id;

;
DROP TABLE layout;

;
ALTER TABLE layout_depend DROP FOREIGN KEY layout_depend_fk_depends_on,
                          DROP FOREIGN KEY layout_depend_fk_layout_id;

;
DROP TABLE layout_depend;

;
ALTER TABLE layout_group DROP FOREIGN KEY layout_group_fk_group_id,
                         DROP FOREIGN KEY layout_group_fk_layout_id;

;
DROP TABLE layout_group;

;
ALTER TABLE metric DROP FOREIGN KEY metric_fk_metric_group;

;
DROP TABLE metric;

;
ALTER TABLE metric_group DROP FOREIGN KEY metric_group_fk_instance_id;

;
DROP TABLE metric_group;

;
DROP TABLE oauthclient;

;
ALTER TABLE oauthtoken DROP FOREIGN KEY oauthtoken_fk_oauthclient_id,
                       DROP FOREIGN KEY oauthtoken_fk_user_id;

;
DROP TABLE oauthtoken;

;
ALTER TABLE organisation DROP FOREIGN KEY organisation_fk_site_id;

;
DROP TABLE organisation;

;
DROP TABLE permission;

;
ALTER TABLE person DROP FOREIGN KEY person_fk_layout_id,
                   DROP FOREIGN KEY person_fk_record_id,
                   DROP FOREIGN KEY person_fk_value;

;
DROP TABLE person;

;
ALTER TABLE rag DROP FOREIGN KEY rag_fk_layout_id;

;
DROP TABLE rag;

;
ALTER TABLE ragval DROP FOREIGN KEY ragval_fk_layout_id,
                   DROP FOREIGN KEY ragval_fk_record_id;

;
DROP TABLE ragval;

;
ALTER TABLE record DROP FOREIGN KEY record_fk_approvedby,
                   DROP FOREIGN KEY record_fk_createdby,
                   DROP FOREIGN KEY record_fk_current_id,
                   DROP FOREIGN KEY record_fk_record_id;

;
DROP TABLE record;

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
DROP TABLE site;

;
ALTER TABLE sort DROP FOREIGN KEY sort_fk_layout_id,
                 DROP FOREIGN KEY sort_fk_parent_id,
                 DROP FOREIGN KEY sort_fk_view_id;

;
DROP TABLE sort;

;
ALTER TABLE string DROP FOREIGN KEY string_fk_layout_id,
                   DROP FOREIGN KEY string_fk_record_id;

;
DROP TABLE string;

;
DROP TABLE submission;

;
ALTER TABLE team DROP FOREIGN KEY team_fk_site_id;

;
DROP TABLE team;

;
ALTER TABLE title DROP FOREIGN KEY title_fk_site_id;

;
DROP TABLE title;

;
ALTER TABLE topic DROP FOREIGN KEY topic_fk_instance_id,
                  DROP FOREIGN KEY topic_fk_prevent_edit_topic_id;

;
DROP TABLE topic;

;
ALTER TABLE user DROP FOREIGN KEY user_fk_department_id,
                 DROP FOREIGN KEY user_fk_lastrecord,
                 DROP FOREIGN KEY user_fk_lastview,
                 DROP FOREIGN KEY user_fk_limit_to_view,
                 DROP FOREIGN KEY user_fk_organisation,
                 DROP FOREIGN KEY user_fk_site_id,
                 DROP FOREIGN KEY user_fk_team_id,
                 DROP FOREIGN KEY user_fk_title;

;
DROP TABLE user;

;
ALTER TABLE user_graph DROP FOREIGN KEY user_graph_fk_graph_id,
                       DROP FOREIGN KEY user_graph_fk_user_id;

;
DROP TABLE user_graph;

;
ALTER TABLE user_group DROP FOREIGN KEY user_group_fk_group_id,
                       DROP FOREIGN KEY user_group_fk_user_id;

;
DROP TABLE user_group;

;
ALTER TABLE user_lastrecord DROP FOREIGN KEY user_lastrecord_fk_instance_id,
                            DROP FOREIGN KEY user_lastrecord_fk_record_id,
                            DROP FOREIGN KEY user_lastrecord_fk_user_id;

;
DROP TABLE user_lastrecord;

;
ALTER TABLE user_permission DROP FOREIGN KEY user_permission_fk_permission_id,
                            DROP FOREIGN KEY user_permission_fk_user_id;

;
DROP TABLE user_permission;

;
ALTER TABLE view DROP FOREIGN KEY view_fk_createdby,
                 DROP FOREIGN KEY view_fk_group_id,
                 DROP FOREIGN KEY view_fk_instance_id,
                 DROP FOREIGN KEY view_fk_user_id;

;
DROP TABLE view;

;
ALTER TABLE view_group DROP FOREIGN KEY view_group_fk_layout_id,
                       DROP FOREIGN KEY view_group_fk_parent_id,
                       DROP FOREIGN KEY view_group_fk_view_id;

;
DROP TABLE view_group;

;
ALTER TABLE view_layout DROP FOREIGN KEY view_layout_fk_layout_id,
                        DROP FOREIGN KEY view_layout_fk_view_id;

;
DROP TABLE view_layout;

;
ALTER TABLE view_limit DROP FOREIGN KEY view_limit_fk_user_id,
                       DROP FOREIGN KEY view_limit_fk_view_id;

;
DROP TABLE view_limit;

;
ALTER TABLE widget DROP FOREIGN KEY widget_fk_dashboard_id,
                   DROP FOREIGN KEY widget_fk_graph_id,
                   DROP FOREIGN KEY widget_fk_view_id;

;
DROP TABLE widget;

;

COMMIT;

